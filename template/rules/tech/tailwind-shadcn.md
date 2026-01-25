# Tailwind + shadcn/ui Integration

> Semantic tokens power shadcn/ui theming.

## How They Work Together

shadcn/ui components use CSS variables that map to Tailwind's semantic tokens:

```css
/* globals.css - defines the variables */
:root {
  --background: 0 0% 100%;
  --foreground: 222.2 84% 4.9%;
  --primary: 222.2 47.4% 11.2%;
  --primary-foreground: 210 40% 98%;
  /* ... */
}

.dark {
  --background: 222.2 84% 4.9%;
  --foreground: 210 40% 98%;
  /* ... */
}
```

```js
// tailwind.config - maps variables to classes
colors: {
  background: 'hsl(var(--background))',
  foreground: 'hsl(var(--foreground))',
  primary: {
    DEFAULT: 'hsl(var(--primary))',
    foreground: 'hsl(var(--primary-foreground))',
  },
}
```

## Extended Semantic Tokens

Beyond shadcn defaults, add project-specific tokens:

```css
:root {
  /* Text hierarchy */
  --strong-text: 222.2 84% 4.9%;
  --base-text: 215.4 16.3% 26.9%;
  --muted-text: 215.4 16.3% 46.9%;

  /* Surfaces */
  --surface: 0 0% 100%;
  --surface-muted: 210 40% 96.1%;
}
```

```js
// tailwind.config
colors: {
  'strong-text': 'hsl(var(--strong-text))',
  'base-text': 'hsl(var(--base-text))',
  'muted-text': 'hsl(var(--muted-text))',
  'surface': 'hsl(var(--surface))',
  'surface-muted': 'hsl(var(--surface-muted))',
}
```

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
