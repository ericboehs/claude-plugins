# JavaScript/TypeScript Linter Patterns

Fix guidance for common JS/TS linter issues (ESLint + Biome). Use these BAD/GOOD patterns to fix lint errors correctly the first time.

## ESLint

### no-unused-vars / @typescript-eslint/no-unused-vars

Remove unused variables or prefix with `_` to signal intentional non-use.

BAD:
```ts
const result = fetchData();
const unused = compute();
return result;
```

GOOD:
```ts
const result = fetchData();
return result;
```

If a destructured value must be skipped: `const [_first, second] = pair`

### no-undef

Every identifier must be declared. Import what you use; don't rely on globals.

BAD:
```ts
const el = document.querySelector('#app');
el.textContent = formatDate(new Date());
```

GOOD:
```ts
import { formatDate } from './utils';
const el = document.querySelector('#app');
el.textContent = formatDate(new Date());
```

For known globals (e.g. `process`, `window`), configure `env` in ESLint config rather than adding inline comments.

### prefer-const / useConst

Use `const` for any binding that is never reassigned.

BAD:
```ts
let name = 'Alice';
let items = getItems();
console.log(name, items);
```

GOOD:
```ts
const name = 'Alice';
const items = getItems();
console.log(name, items);
```

Only use `let` when the variable is explicitly reassigned later in the same scope.

### no-var

Never use `var`. It is function-scoped and hoisted in surprising ways. Always use `const` or `let`.

BAD:
```ts
var count = 0;
for (var i = 0; i < 10; i++) { count += i; }
```

GOOD:
```ts
let count = 0;
for (let i = 0; i < 10; i++) { count += i; }
```

### eqeqeq / noDoubleEquals

Always use `===` and `!==`. Loose equality (`==`) coerces types silently.

BAD:
```ts
if (value == null) return;
if (status == 0) reset();
```

GOOD:
```ts
if (value === null || value === undefined) return;
if (status === 0) reset();
```

Exception: `value == null` catching both `null` and `undefined` is a known pattern — disable inline if intentional and document why.

### no-console

Remove `console.*` calls from production code. Use a proper logger.

BAD:
```ts
function processOrder(order: Order) {
  console.log('Processing', order.id);
  return submit(order);
}
```

GOOD:
```ts
import { logger } from './logger';

function processOrder(order: Order) {
  logger.info('Processing order', { id: order.id });
  return submit(order);
}
```

For scripts/CLIs where console output is intentional, disable the rule per-file with a comment at the top.

### @typescript-eslint/no-explicit-any / noExplicitAny

Avoid `any`. Use `unknown` for values of uncertain shape, or define a proper type.

BAD:
```ts
function parse(input: any): any {
  return JSON.parse(input);
}
```

GOOD:
```ts
function parse(input: string): unknown {
  return JSON.parse(input);
}

// Or with a defined type:
function parse<T>(input: string): T {
  return JSON.parse(input) as T;
}
```

If integrating with an untyped third-party library, prefer `// eslint-disable-next-line` with a comment explaining the constraint over spreading `any` through the codebase.

### react-hooks/exhaustive-deps

Every value from the component scope used inside `useEffect`, `useCallback`, or `useMemo` must be listed in the dependency array.

BAD:
```tsx
useEffect(() => {
  fetchUser(userId);
}, []); // userId missing
```

GOOD:
```tsx
useEffect(() => {
  fetchUser(userId);
}, [userId]);
```

If a dependency changes too often and causes loops, stabilize it with `useRef` or `useCallback` upstream — don't omit it from the array.

### import/order

Imports must be grouped and ordered: builtin → external → internal → relative. Each group separated by a blank line.

BAD:
```ts
import { useState } from 'react';
import { db } from './db';
import fs from 'fs';
import { Button } from '@/components/Button';
```

GOOD:
```ts
import fs from 'fs';

import { useState } from 'react';

import { Button } from '@/components/Button';
import { db } from './db';
```

Configure path aliases in the ESLint import resolver so internal aliases (`@/`) are recognized as internal, not external.

## Biome

### noUnusedVariables

Same as ESLint `no-unused-vars`. Remove the binding or prefix with `_`.

BAD:
```ts
const temp = expensiveCompute();
return cached;
```

GOOD:
```ts
return cached;
```

### useTemplate (template literals vs concatenation)

Use template literals instead of string concatenation.

BAD:
```ts
const msg = 'Hello, ' + name + '! You have ' + count + ' messages.';
const url = baseUrl + '/api/' + version + '/users';
```

GOOD:
```ts
const msg = `Hello, ${name}! You have ${count} messages.`;
const url = `${baseUrl}/api/${version}/users`;
```
