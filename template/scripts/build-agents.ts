#!/usr/bin/env npx tsx
/**
 * Agent Build Script
 *
 * Generates .claude/agents/*.md files from .claude/agents-src/*.yaml definitions.
 *
 * Features:
 * - Variable substitution ($skillSets.patterns, $colors.review, etc.)
 * - Shared configuration from _shared.yaml
 * - Structured examples converted to proper format
 * - Validation of required fields
 *
 * Usage:
 *   npx tsx .claude/scripts/build-agents.ts
 *   npm run build:agents
 */
import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'yaml';

// Paths
const AGENTS_SRC_DIR = path.join(process.cwd(), '.claude', 'agents-src');
const AGENTS_OUT_DIR = path.join(process.cwd(), '.claude', 'agents');
const SHARED_CONFIG_PATH = path.join(AGENTS_SRC_DIR, '_shared.yaml');

// Types
interface SharedConfig {
  defaults: {
    model: string;
  };
  skillSets: Record<string, string[]>;
  toolSets: Record<string, string[]>;
  includes: Record<string, string>;
  ruleBundles: Record<string, string[]>;
  colors: Record<string, string>;
}

interface AgentExample {
  context: string;
  user: string;
  assistant: string;
  commentary: string;
}

interface AgentDescription {
  summary: string;
  examples: AgentExample[];
}

interface AgentDefinition {
  name: string;
  color?: string;
  model?: string;
  skills?: string | string[];
  tools?: string | string[];
  permissionMode?: string;
  includes?: string[];
  description: AgentDescription;
  body: string;
}

// Load shared configuration
function loadSharedConfig(): SharedConfig {
  if (!fs.existsSync(SHARED_CONFIG_PATH)) {
    console.error(`Error: Shared config not found at ${SHARED_CONFIG_PATH}`);
    process.exit(1);
  }

  const content = fs.readFileSync(SHARED_CONFIG_PATH, 'utf-8');
  return yaml.parse(content) as SharedConfig;
}

// Resolve variable references like $skillSets.patterns or $colors.review
function resolveVariable(value: string, shared: SharedConfig): string | string[] | undefined {
  if (!value.startsWith('$')) return value;

  const parts = value.slice(1).split('.');
  if (parts.length !== 2) {
    console.warn(`Warning: Invalid variable reference: ${value}`);
    return value;
  }

  const [category, key] = parts;

  switch (category) {
    case 'skillSets':
      return shared.skillSets[key];
    case 'toolSets':
      return shared.toolSets[key];
    case 'includes':
      return shared.includes[key];
    case 'ruleBundles':
      return shared.ruleBundles[key];
    case 'colors':
      return shared.colors[key];
    default:
      console.warn(`Warning: Unknown category: ${category}`);
      return value;
  }
}

// Resolve all variables in agent definition
function resolveAgentVariables(agent: AgentDefinition, shared: SharedConfig): AgentDefinition {
  const resolved = { ...agent };

  // Resolve color
  if (typeof resolved.color === 'string' && resolved.color.startsWith('$')) {
    resolved.color = resolveVariable(resolved.color, shared) as string;
  }

  // Resolve skills
  if (typeof resolved.skills === 'string' && resolved.skills.startsWith('$')) {
    resolved.skills = resolveVariable(resolved.skills, shared) as string[];
  }

  // Resolve tools
  if (typeof resolved.tools === 'string' && resolved.tools.startsWith('$')) {
    resolved.tools = resolveVariable(resolved.tools, shared) as string[];
  }

  // Resolve includes
  // Handle both string (e.g., $ruleBundles.implementation) and array formats
  if (resolved.includes) {
    // Normalize to array
    const includesArray: string[] =
      typeof resolved.includes === 'string' ? [resolved.includes] : resolved.includes;

    // Resolve variables, flattening ruleBundles that return arrays
    const resolvedIncludes: string[] = [];
    for (const inc of includesArray) {
      if (inc.startsWith('$')) {
        const resolvedValue = resolveVariable(inc, shared);
        if (Array.isArray(resolvedValue)) {
          // ruleBundles return arrays of $includes.* references that need further resolution
          for (const nestedInc of resolvedValue) {
            if (typeof nestedInc === 'string' && nestedInc.startsWith('$')) {
              const finalValue = resolveVariable(nestedInc, shared);
              resolvedIncludes.push(finalValue as string);
            } else {
              resolvedIncludes.push(nestedInc as string);
            }
          }
        } else {
          resolvedIncludes.push(resolvedValue as string);
        }
      } else {
        resolvedIncludes.push(inc);
      }
    }
    resolved.includes = resolvedIncludes;
  }

  // Apply defaults
  if (!resolved.model) {
    resolved.model = shared.defaults.model;
  }

  return resolved;
}

// Format examples into the required description format
function formatDescription(desc: AgentDescription): string {
  let result = desc.summary.trim();

  if (desc.examples && desc.examples.length > 0) {
    for (const example of desc.examples) {
      result += `\\n\\n<example>\\nContext: ${example.context}\\nuser: "${example.user}"\\nassistant: "${example.assistant}"\\n<commentary>\\n${example.commentary}\\n</commentary>\\n</example>`;
    }
  }

  return result;
}

// Generate the markdown frontmatter
function generateFrontmatter(agent: AgentDefinition): string {
  const lines: string[] = ['---'];

  // Required fields
  lines.push(`name: ${agent.name}`);
  lines.push(`description: ${formatDescription(agent.description)}`);

  // Optional fields
  if (agent.model) {
    lines.push(`model: ${agent.model}`);
  }

  if (agent.color) {
    lines.push(`color: ${agent.color}`);
  }

  if (agent.tools && Array.isArray(agent.tools)) {
    lines.push(`tools: ${JSON.stringify(agent.tools)}`);
  }

  if (agent.skills && Array.isArray(agent.skills)) {
    lines.push(`skills: ${agent.skills.join(', ')}`);
  }

  if (agent.permissionMode) {
    lines.push(`permissionMode: ${agent.permissionMode}`);
  }

  lines.push('---');

  return lines.join('\n');
}

// Generate the full agent markdown
function generateAgentMarkdown(agent: AgentDefinition): string {
  const frontmatter = generateFrontmatter(agent);

  // Build includes section
  let includesSection = '';
  if (agent.includes && agent.includes.length > 0) {
    includesSection = agent.includes.join('\n\n') + '\n\n';
  }

  // Combine all parts
  return `${frontmatter}\n\n${includesSection}${agent.body.trim()}\n`;
}

// Validate agent definition
function validateAgent(agent: AgentDefinition, filename: string): boolean {
  const errors: string[] = [];

  if (!agent.name) {
    errors.push('Missing required field: name');
  } else {
    // Validate name format
    if (!/^[a-z][a-z0-9-]{1,48}[a-z0-9]$/.test(agent.name)) {
      errors.push(`Invalid name format: "${agent.name}" (must be lowercase, hyphens, 3-50 chars)`);
    }
  }

  if (!agent.description) {
    errors.push('Missing required field: description');
  } else {
    if (!agent.description.summary) {
      errors.push('Missing required field: description.summary');
    }
    if (!agent.description.examples || agent.description.examples.length === 0) {
      errors.push('Missing required field: description.examples (need at least 1)');
    }
  }

  if (!agent.body) {
    errors.push('Missing required field: body');
  }

  if (errors.length > 0) {
    console.error(`\nValidation errors in ${filename}:`);
    errors.forEach((err) => console.error(`  - ${err}`));
    return false;
  }

  return true;
}

// Main build function
function build(validateOnly = false): void {
  console.log(
    validateOnly
      ? 'Validating agent definitions...\n'
      : 'Building agents from YAML definitions...\n',
  );

  // Load shared config
  const shared = loadSharedConfig();
  console.log('✓ Loaded shared configuration');

  // Find all agent YAML files
  const files = fs.readdirSync(AGENTS_SRC_DIR).filter((f) => {
    return f.endsWith('.yaml') && !f.startsWith('_');
  });

  if (files.length === 0) {
    console.log('No agent definitions found in', AGENTS_SRC_DIR);
    return;
  }

  console.log(`✓ Found ${files.length} agent definition(s)\n`);

  // Ensure output directory exists
  if (!fs.existsSync(AGENTS_OUT_DIR)) {
    fs.mkdirSync(AGENTS_OUT_DIR, { recursive: true });
  }

  let successCount = 0;
  let errorCount = 0;

  // Process each agent
  for (const file of files) {
    const filePath = path.join(AGENTS_SRC_DIR, file);
    const content = fs.readFileSync(filePath, 'utf-8');

    try {
      const agent = yaml.parse(content) as AgentDefinition;

      // Validate
      if (!validateAgent(agent, file)) {
        errorCount++;
        continue;
      }

      // Resolve variables
      const resolved = resolveAgentVariables(agent, shared);

      // Generate markdown
      const markdown = generateAgentMarkdown(resolved);

      // Write output file (unless validate-only mode)
      if (!validateOnly) {
        const outFile = path.join(AGENTS_OUT_DIR, `${resolved.name}.md`);
        fs.writeFileSync(outFile, markdown);
        console.log(`✓ Generated ${resolved.name}.md`);
      } else {
        console.log(`✓ Validated ${resolved.name}`);
      }
      successCount++;
    } catch (err) {
      console.error(`✗ Error processing ${file}:`, err);
      errorCount++;
    }
  }

  console.log(`\nBuild complete: ${successCount} succeeded, ${errorCount} failed`);

  if (errorCount > 0) {
    process.exit(1);
  }
}

// Parse command line args
const args = process.argv.slice(2);
const validateOnly = args.includes('--validate');

// Run build
build(validateOnly);
