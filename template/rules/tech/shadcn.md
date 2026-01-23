# shadcn/ui Patterns

> Copy-paste components built on Radix UI. Owns the code.

## Core Principle

shadcn/ui provides pre-built, accessible components that you copy into your codebase. You own the code - modify freely.

## Component Usage

Always use shadcn/ui components instead of raw HTML:

```tsx
// Good - accessible, consistent
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

<Button onClick={handleClick}>Submit</Button>
<Input type="email" placeholder="Email" />
<Card>
  <CardHeader>
    <CardTitle>Title</CardTitle>
  </CardHeader>
  <CardContent>Content</CardContent>
</Card>

// Bad - inconsistent, accessibility issues
<button onClick={handleClick}>Submit</button>
<input type="email" placeholder="Email" />
<div className="rounded border p-4">Content</div>
```

## Common Components

| Component | Use Case |
|-----------|----------|
| `Button` | All clickable actions |
| `Input`, `Textarea` | Form fields |
| `Select` | Dropdowns |
| `Dialog` | Modals |
| `Sheet` | Slide-out panels |
| `Card` | Content containers |
| `Table` | Data tables |
| `Toast` | Notifications |
| `Form` | Form with validation |

## Button Variants

```tsx
<Button>Default</Button>
<Button variant="destructive">Delete</Button>
<Button variant="outline">Cancel</Button>
<Button variant="ghost">Subtle</Button>
<Button variant="link">Link</Button>
<Button size="sm">Small</Button>
<Button size="lg">Large</Button>
```

## Form Pattern

Use with react-hook-form and zod:

```tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Form, FormField, FormItem, FormLabel, FormControl, FormMessage } from '@/components/ui/form';

const form = useForm({
  resolver: zodResolver(schema),
  defaultValues: { name: '' },
});

<Form {...form}>
  <form onSubmit={form.handleSubmit(onSubmit)}>
    <FormField
      control={form.control}
      name="name"
      render={({ field }) => (
        <FormItem>
          <FormLabel>Name</FormLabel>
          <FormControl>
            <Input {...field} />
          </FormControl>
          <FormMessage />
        </FormItem>
      )}
    />
    <Button type="submit">Submit</Button>
  </form>
</Form>
```

## Dialog Pattern

```tsx
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';

<Dialog>
  <DialogTrigger asChild>
    <Button>Open</Button>
  </DialogTrigger>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Title</DialogTitle>
    </DialogHeader>
    {/* Content */}
  </DialogContent>
</Dialog>
```

## Adding Components

```bash
npx shadcn@latest add button
npx shadcn@latest add card
npx shadcn@latest add dialog
```

Components are added to `components/ui/`.

## Danger Zone

| Never | Consequence |
|-------|-------------|
| Raw HTML (`<button>`, `<input>`) | Inconsistent styling, accessibility issues |
| Modify components in place without reason | Hard to update later |
| Skip `asChild` on trigger components | Wrong element in DOM |
| Forget Form wrapper with FormField | Validation doesn't work |
