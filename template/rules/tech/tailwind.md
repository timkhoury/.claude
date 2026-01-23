# Tailwind CSS Patterns

> Utility-first CSS. Use semantic tokens for theming.

## Semantic Color Tokens

Define semantic tokens in your Tailwind config, then use them consistently:

```tsx
// Good - semantic, theme-aware
<h1 className="text-strong-text">Title</h1>
<p className="text-muted-text">Description</p>
<button className="bg-primary hover:bg-primary-emphasis">Click</button>
<div className="border-border bg-surface">Card</div>

// Bad - raw colors break theming
<h1 className="text-gray-900">Title</h1>
<p className="text-gray-500">Description</p>
```

## Common Semantic Tokens

| Token | Purpose |
|-------|---------|
| `text-strong-text` | Headings, emphasis |
| `text-base-text` | Body text |
| `text-muted-text` | Secondary content |
| `bg-surface` | Card/container backgrounds |
| `bg-surface-muted` | Subtle backgrounds |
| `border-border` | Default borders |
| `bg-primary` | Primary actions |
| `bg-destructive` | Dangerous actions |

## Dark Mode

Semantic tokens + Tailwind dark mode = automatic theming:

```tsx
// Tokens handle dark mode automatically
<div className="bg-surface text-base-text">
  Works in light and dark mode
</div>
```

No need for `dark:` prefixes when using semantic tokens.

## Responsive Design

Mobile-first breakpoints:

```tsx
<div className="px-4 md:px-6 lg:px-8">
  <h1 className="text-xl md:text-2xl lg:text-3xl">Responsive</h1>
</div>
```

| Prefix | Min Width |
|--------|-----------|
| (none) | 0px (mobile) |
| `sm:` | 640px |
| `md:` | 768px |
| `lg:` | 1024px |
| `xl:` | 1280px |

## Spacing Patterns

```tsx
// Stack with gap
<div className="flex flex-col gap-4">
  <Item />
  <Item />
</div>

// Horizontal with gap
<div className="flex gap-2">
  <Button />
  <Button />
</div>

// Padding
<div className="p-4 md:p-6">Content</div>
```

## List Patterns

Prefer bordered lists with dividers over individual cards:

```tsx
// Good - clean, compact, aligned
<div className="divide-y divide-border rounded-lg border border-border">
  {items.map((item) => (
    <div key={item.id} className="px-4 py-3">
      {/* Row content */}
    </div>
  ))}
</div>

// Avoid - heavy visual weight
<div className="space-y-2">
  {items.map((item) => (
    <div className="rounded-lg border p-4 shadow">
      {/* Card content */}
    </div>
  ))}
</div>
```

## Danger Zone

| Never | Consequence |
|-------|-------------|
| Raw colors (`text-gray-500`) | Breaks dark mode, inconsistent theming |
| Hardcoded px values (`w-[347px]`) | Inflexible, breaks responsiveness |
| Excessive arbitrary values | Defeats utility-first purpose |
| `!important` via `!` prefix | Sign of specificity war |
