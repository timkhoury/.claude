# Tailwind + shadcn/ui Integration

> How semantic tokens and shadcn/ui work together. See `tailwind.md` for token usage, `shadcn.md` for components.

## Architecture

shadcn/ui uses CSS variables → Tailwind maps them to classes → Dark mode handled automatically.

```
globals.css (--primary: ...)  →  tailwind.config (primary: hsl(var(--primary)))  →  className="bg-primary"
```

## Extended Tokens

Add project-specific tokens in `globals.css`, map in `tailwind.config`:

| Token | Purpose | CSS Variable |
|-------|---------|--------------|
| `text-strong-text` | Headings | `--strong-text` |
| `text-base-text` | Body | `--base-text` |
| `text-muted-text` | Secondary | `--muted-text` |
| `bg-surface` | Cards | `--surface` |
| `bg-surface-muted` | Subtle BG | `--surface-muted` |

## Using Together

```tsx
// shadcn component with Tailwind utilities
<Card className="bg-surface-muted">
  <CardHeader>
    <CardTitle className="text-strong-text">Title</CardTitle>
  </CardHeader>
  <CardContent className="text-muted-text">
    Content here
  </CardContent>
</Card>

// Button with extra styling
<Button className="w-full md:w-auto">
  Submit
</Button>
```

## Customizing Components

Extend component variants using `cn()` utility:

```tsx
// In your component
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';

<Button className={cn('gap-2', isActive && 'bg-primary-emphasis')}>
  <Icon />
  Label
</Button>
```

## Content Tone

Professional UI copy:

```tsx
// Good - professional, precise
<CardTitle>Settings</CardTitle>
<p className="text-muted-text">Manage your account preferences.</p>
<Button>Save changes</Button>

// Bad - unprofessional
<CardTitle>Settings!</CardTitle>
<p>Awesome account settings await!</p>
<Button>Let's go! 🚀</Button>
```

## Danger Zone

| Never | Consequence |
|-------|-------------|
| Override CSS variables inline | Breaks theming consistency |
| Skip `cn()` for conditional classes | Wrong class merge behavior |
| Use raw colors alongside shadcn | Visual inconsistency |
| Exclamation marks in UI copy | Unprofessional tone |
| Emojis in production UI | Off-brand |
