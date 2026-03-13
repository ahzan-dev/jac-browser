# Issue Taxonomy

## Severity Levels

| Level | Description | Examples |
|-------|-------------|----------|
| **Critical** | Blocks core workflow, data loss, crashes | App crashes on submit, data deleted without confirmation |
| **High** | Major feature broken, no workaround | Login fails, page won't load, form rejects valid input |
| **Medium** | Feature works with noticeable problems | Slow response, layout broken on resize, wrong error message |
| **Low** | Minor cosmetic/polish | Typo, slight misalignment, inconsistent spacing |

## Categories

### Visual/UI
- Layout breaks, misalignment
- Clipped or overlapping text
- Missing icons or images
- Dark/light mode rendering issues
- Responsive breakpoint problems
- Z-index/layering issues
- Font rendering problems
- Color contrast failures
- Animation glitches

### Functional
- Broken links (404, wrong destination)
- Buttons that do nothing on click
- Bad form validation (rejects valid input, accepts invalid)
- Incorrect redirects
- Silent failures (action appears to work but doesn't)
- State not persisted (data lost on refresh)
- Race conditions (click too fast = broken state)
- Broken search/filtering
- Pagination issues
- File upload/download failures

### UX
- Confusing navigation (can't find feature)
- Missing loading indicators
- Slow/unresponsive interactions (>300ms feedback)
- Unclear error messages
- Missing confirmation for destructive actions
- Dead ends (no way back)
- Inconsistent interaction patterns
- Missing keyboard shortcuts
- Unintuitive defaults
- Missing empty states

### Content
- Typos and grammar errors
- Outdated information
- Placeholder/lorem ipsum text left in
- Truncated text without tooltip
- Missing labels or descriptions
- Inconsistent terminology

### Performance
- Slow page loads (>3 seconds)
- Janky scrolling or animations
- Large layout shifts (CLS)
- Excessive network requests
- Memory leaks (gets slower over time)
- Unoptimized images

### Console/Errors
- JavaScript exceptions
- Failed network requests (4xx, 5xx)
- Deprecation warnings
- CORS errors
- Mixed content warnings
- Unhandled promise rejections

### Accessibility
- Missing alt text on images
- Unlabeled form inputs
- Poor keyboard navigation
- Focus traps
- Insufficient color contrast
- Missing ARIA attributes
- Screen reader incompatibility

## Exploration Checklist

1. **Visual scan** - Take screenshot, look for layout/alignment issues
2. **Interactive elements** - Click every button, link, control
3. **Forms** - Fill and submit; test empty submission, invalid input
4. **Navigation** - Follow all paths; check breadcrumbs, back button
5. **States** - Check empty states, loading states, error states
6. **Console** - Check for JS errors, failed network requests
7. **Responsiveness** - Test at different viewport sizes
8. **Auth boundaries** - Test when not logged in, different roles
