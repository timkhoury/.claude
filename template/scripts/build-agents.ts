#!/usr/bin/env npx tsx
/**
 * Agent Build Script
 *
 * Generates .claude/agents/*.md files from .claude/agents-src/*.yaml definitions.
 *
 * Features:
 * - Variable substitution ($skillSets.patterns, $colors.review, etc.)
 * - Split configuration: _template.yaml (shared) + _project.yaml (project-specific)
 * - Folder-based includes with auto-discovery
 * - Structured examples converted to proper format
 * - Validation of required fields
 *
 * Configuration Files:
 *   _template.yaml - Template-controlled (syncs from ~/.claude/template/)
 *   _project.yaml  - Project-specific (never syncs, customized locally)
 *
 * Merge Strategy:
 *   - ruleBundles: project rules prepended to template rules
 *   - skillSets/toolSets: project extends template (object spread)
 *   - Other fields: template values used (project doesn't override)
 *
 * Folder Includes:
 *   includes:
 *     tech: "@/.claude/rules/tech/"    # Trailing / = folder
 *
 *   ruleBundles:
 *     implementation:
 *       - $includes.tech              # All files from folder
 *       - $includes.tech.vitest       # Specific file from folder
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
const TEMPLATE_CONFIG_PATH = path.join(AGENTS_SRC_DIR, '_template.yaml');
const PROJECT_CONFIG_PATH = path.join(AGENTS_SRC_DIR, '_project.yaml');
const PROJECT_ROOT = process.cwd();

// Types
interface FolderInclude {
  basePath: string;
  files: Map<string, string>; // camelCase key -> full path
}

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

interface ResolvedIncludes {
  files: Record<string, string>; // Individual file includes
  folders: Record<string, FolderInclude>; // Folder includes with discovered files
}

interface AgentExample {
  context: string;
  user: string;
  assistant: string;
  commentary: string;
}

// Helper: Convert kebab-case to camelCase
function kebabToCamel(str: string): string {
  return str.replace(/-([a-z])/g, (_, letter) => letter.toUpperCase());
}

// Helper: Parse YAML frontmatter from markdown file
function parseFrontmatter(content: string, filePath?: string): Record<string, unknown> {
  const match = content.match(/^---\n([\s\S]*?)\n---/);
  if (!match) return {};
  try {
    return yaml.parse(match[1]) as Record<string, unknown>;
  } catch {
    console.warn(`Warning: Failed to parse frontmatter${filePath ? ` in ${filePath}` : ''}`);
    return {};
  }
}

// Default bundles for project rules (convention-based)
const DEFAULT_PROJECT_BUNDLES = ['implementation', 'review', 'planning'];
const ALL_BUNDLES = ['implementation', 'review', 'planning', 'testing'];

// Discover project rules and their bundle assignments from frontmatter
function discoverProjectRuleBundles(projectFolderPath: string): Record<string, string[]> {
  const bundleAssignments: Record<string, string[]> = {};
  const resolvedPath = resolveIncludePath(projectFolderPath);

  if (!fs.existsSync(resolvedPath)) {
    return bundleAssignments;
  }

  const entries = fs.readdirSync(resolvedPath);
  for (const entry of entries) {
    if (!entry.endsWith('.md')) continue;

    const filePath = path.join(resolvedPath, entry);
    const content = fs.readFileSync(filePath, 'utf-8');
    const frontmatter = parseFrontmatter(content, filePath);

    // Determine bundles: frontmatter > default
    let bundles: string[];
    if (frontmatter.bundles === 'all') {
      bundles = ALL_BUNDLES;
    } else if (Array.isArray(frontmatter.bundles)) {
      bundles = frontmatter.bundles as string[];
    } else {
      bundles = DEFAULT_PROJECT_BUNDLES;
    }

    const basename = entry.slice(0, -3); // Remove .md
    const camelKey = kebabToCamel(basename);
    const includePath = `$includes.project.${camelKey}`;

    for (const bundle of bundles) {
      if (!bundleAssignments[bundle]) {
        bundleAssignments[bundle] = [];
      }
      bundleAssignments[bundle].push(includePath);
    }
  }

  return bundleAssignments;
}

// Helper: Resolve @/ path to actual filesystem path
function resolveIncludePath(includePath: string): string {
  if (includePath.startsWith('@/')) {
    return path.join(PROJECT_ROOT, includePath.slice(2));
  }
  return includePath;
}

// Helper: Check if include path is a folder (ends with /)
function isFolderInclude(includePath: string): boolean {
  return includePath.endsWith('/');
}

// Helper: Discover all .md files in a folder
function discoverFolderFiles(folderPath: string): Map<string, string> {
  const files = new Map<string, string>();
  const resolvedPath = resolveIncludePath(folderPath);

  if (!fs.existsSync(resolvedPath)) {
    console.warn(`Warning: Folder not found: ${resolvedPath}`);
    return files;
  }

  const entries = fs.readdirSync(resolvedPath);
  for (const entry of entries) {
    if (entry.endsWith('.md')) {
      const basename = entry.slice(0, -3); // Remove .md extension
      const camelKey = kebabToCamel(basename);
      // Store the original @/ path format for the include
      const fullPath = folderPath + entry;
      files.set(camelKey, fullPath);
    }
  }

  return files;
}

// Process includes to separate files and folders
function processIncludes(includes: Record<string, string>): ResolvedIncludes {
  const result: ResolvedIncludes = {
    files: {},
    folders: {},
  };

  for (const [key, value] of Object.entries(includes)) {
    if (isFolderInclude(value)) {
      result.folders[key] = {
        basePath: value,
        files: discoverFolderFiles(value),
      };
    } else {
      result.files[key] = value;
    }
  }

  return result;
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

// Load template configuration (required)
function loadTemplateConfig(): SharedConfig {
  if (!fs.existsSync(TEMPLATE_CONFIG_PATH)) {
    console.error(`Error: Template config not found at ${TEMPLATE_CONFIG_PATH}`);
    process.exit(1);
  }

  const content = fs.readFileSync(TEMPLATE_CONFIG_PATH, 'utf-8');
  return yaml.parse(content) as SharedConfig;
}

// Load project configuration (optional)
function loadProjectConfig(): Partial<SharedConfig> {
  if (!fs.existsSync(PROJECT_CONFIG_PATH)) {
    return {};
  }

  const content = fs.readFileSync(PROJECT_CONFIG_PATH, 'utf-8');
  const parsed = yaml.parse(content);
  return (parsed ?? {}) as Partial<SharedConfig>;
}

// Merge template and project configs
// - ruleBundles: auto-discovered project rules + explicit project rules + template rules
// - skillSets/toolSets: project extends template
// - Other fields: template values used
function mergeConfigs(template: SharedConfig, project: Partial<SharedConfig>): SharedConfig {
  const merged: SharedConfig = { ...template };

  // Auto-discover project rules from frontmatter
  const projectFolderPath = template.includes?.project;
  const autoDiscoveredBundles = projectFolderPath
    ? discoverProjectRuleBundles(projectFolderPath)
    : {};

  // Start with template bundles
  merged.ruleBundles = { ...template.ruleBundles };

  // Prepend auto-discovered project rules
  for (const [bundle, rules] of Object.entries(autoDiscoveredBundles)) {
    if (merged.ruleBundles[bundle]) {
      merged.ruleBundles[bundle] = [...rules, ...merged.ruleBundles[bundle]];
    } else {
      merged.ruleBundles[bundle] = rules;
    }
  }

  // Then prepend explicit project rules (these go before auto-discovered)
  if (project.ruleBundles) {
    for (const [bundle, rules] of Object.entries(project.ruleBundles)) {
      if (merged.ruleBundles[bundle]) {
        merged.ruleBundles[bundle] = [...rules, ...merged.ruleBundles[bundle]];
      } else {
        merged.ruleBundles[bundle] = rules;
      }
    }
  }

  // Merge skillSets: project extends template
  if (project.skillSets) {
    merged.skillSets = { ...template.skillSets, ...project.skillSets };
  }

  // Merge toolSets: project extends template
  if (project.toolSets) {
    merged.toolSets = { ...template.toolSets, ...project.toolSets };
  }

  return merged;
}

// Load and merge configurations
function loadConfigs(): SharedConfig {
  const template = loadTemplateConfig();
  const project = loadProjectConfig();
  return mergeConfigs(template, project);
}

// Resolve variable references like $skillSets.patterns or $colors.review
// Also handles folder includes: $includes.tech (all) or $includes.tech.vitest (specific)
function resolveVariable(
  value: string,
  shared: SharedConfig,
  resolvedIncludes: ResolvedIncludes,
): string | string[] | undefined {
  if (!value.startsWith('$')) return value;

  const parts = value.slice(1).split('.');

  // Handle includes specially for folder support
  if (parts[0] === 'includes') {
    if (parts.length === 2) {
      const key = parts[1];
      // Check if it's a folder include
      if (resolvedIncludes.folders[key]) {
        // Return all files from the folder
        return Array.from(resolvedIncludes.folders[key].files.values());
      }
      // Otherwise it's an individual file include
      return resolvedIncludes.files[key];
    } else if (parts.length === 3) {
      // $includes.folder.file syntax
      const [, folderKey, fileKey] = parts;
      const folder = resolvedIncludes.folders[folderKey];
      if (folder) {
        const filePath = folder.files.get(fileKey);
        if (!filePath) {
          console.warn(
            `Warning: File "${fileKey}" not found in folder "${folderKey}". Available: ${Array.from(folder.files.keys()).join(', ')}`,
          );
        }
        return filePath;
      }
      console.warn(`Warning: Folder "${folderKey}" not found in includes`);
      return value;
    }
  }

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
function resolveAgentVariables(
  agent: AgentDefinition,
  shared: SharedConfig,
  resolvedIncludes: ResolvedIncludes,
): AgentDefinition {
  const resolved = { ...agent };

  // Resolve color
  if (typeof resolved.color === 'string' && resolved.color.startsWith('$')) {
    resolved.color = resolveVariable(resolved.color, shared, resolvedIncludes) as string;
  }

  // Resolve skills
  if (typeof resolved.skills === 'string' && resolved.skills.startsWith('$')) {
    resolved.skills = resolveVariable(resolved.skills, shared, resolvedIncludes) as string[];
  }

  // Resolve tools
  if (typeof resolved.tools === 'string' && resolved.tools.startsWith('$')) {
    resolved.tools = resolveVariable(resolved.tools, shared, resolvedIncludes) as string[];
  }

  // Resolve includes
  // Handle both string (e.g., $ruleBundles.implementation) and array formats
  if (resolved.includes) {
    // Normalize to array
    const includesArray: string[] =
      typeof resolved.includes === 'string' ? [resolved.includes] : resolved.includes;

    // Resolve variables, flattening ruleBundles and folder includes that return arrays
    const finalIncludes: string[] = [];
    for (const inc of includesArray) {
      if (inc.startsWith('$')) {
        const resolvedValue = resolveVariable(inc, shared, resolvedIncludes);
        if (Array.isArray(resolvedValue)) {
          // Could be a ruleBundle (array of $includes.*) or folder include (array of paths)
          for (const nestedInc of resolvedValue) {
            if (typeof nestedInc === 'string' && nestedInc.startsWith('$')) {
              // ruleBundle entry - resolve further
              const finalValue = resolveVariable(nestedInc, shared, resolvedIncludes);
              if (Array.isArray(finalValue)) {
                // Folder include expanded to multiple files
                finalIncludes.push(...finalValue);
              } else if (finalValue) {
                finalIncludes.push(finalValue as string);
              }
            } else {
              // Already a path (from folder include)
              finalIncludes.push(nestedInc as string);
            }
          }
        } else if (resolvedValue) {
          finalIncludes.push(resolvedValue as string);
        }
      } else {
        finalIncludes.push(inc);
      }
    }
    resolved.includes = finalIncludes;
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

  // Load and merge configs
  const shared = loadConfigs();
  const hasProjectConfig = fs.existsSync(PROJECT_CONFIG_PATH);
  console.log(`✓ Loaded configuration (template${hasProjectConfig ? ' + project' : ''})`);

  // Process includes to discover folder contents
  const resolvedIncludes = processIncludes(shared.includes);
  const folderCount = Object.keys(resolvedIncludes.folders).length;
  const fileCount = Object.keys(resolvedIncludes.files).length;
  let totalFilesInFolders = 0;
  for (const folder of Object.values(resolvedIncludes.folders)) {
    totalFilesInFolders += folder.files.size;
  }
  console.log(
    `✓ Processed includes: ${fileCount} files, ${folderCount} folders (${totalFilesInFolders} files discovered)`,
  );

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
      const resolved = resolveAgentVariables(agent, shared, resolvedIncludes);

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
