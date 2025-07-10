# Claude Development Preferences

This file contains development philosophy and preferences for working on the Spinbox project.

## Core Philosophy: Keep Everything Simple

**Primary Rule**: Always choose the simplest possible implementation that works.

## Testing Philosophy

- **Always keep testing SUPER SIMPLE**
- Minimal dependencies (preferably none)
- Fast execution (< 5 seconds target)
- Essential coverage only (core functionality users actually need)
- No complex test frameworks or infinite loops
- Self-contained assertion functions
- Clear, readable test output
- Avoid over-engineering test infrastructure

### Testing Examples
✅ **Good**: 22 focused tests in simple-test.sh that run in < 5 seconds
❌ **Bad**: 115+ test functions with complex dependencies that hang

## General Implementation Philosophy

- **Prefer minimal solutions over complex ones**
- Avoid over-engineering and unnecessary abstractions
- Focus on what users actually need, not theoretical completeness
- Keep dependencies to a minimum
- Make things work reliably first, optimize later if needed
- Choose readability over cleverness
- Eliminate infinite loops, timeouts, and hanging processes

## Decision Making Guidelines

When choosing between multiple approaches:
1. **Simple vs Complex**: Always choose simple
2. **Few dependencies vs Many**: Always choose fewer
3. **Fast vs Slow**: Always choose fast
4. **Essential vs Complete**: Always choose essential
5. **Reliable vs Feature-rich**: Always choose reliable

## Code Quality Principles

- Write code that's easy to understand and modify
- Prefer explicit over implicit behavior
- Use clear naming and minimal comments
- Eliminate unnecessary complexity
- Make failures obvious and fast

## Memory Note

**This is a critical preference**: The user strongly values simplicity above all else. When in doubt, always err on the side of the simpler solution, especially for testing infrastructure.

---

*Remember: The goal is reliable, maintainable software that does what users need without unnecessary complexity.*