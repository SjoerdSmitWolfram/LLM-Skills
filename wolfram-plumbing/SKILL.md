---
name: wolfram-plumbing
description: 'Examine internal implementations of Wolfram Language built-in functions when documentation is insufficient. Uses DefinitionString to reveal actual function definitions, sub-functions, and implementation patterns.'
argument-hint: 'Function name to inspect (e.g., "Parallelize", "Compile", "NDSolve")'
---

# Wolfram Language Function Plumbing

## When to Use
- wolfram-docs skill provides insufficient detail about function behavior
- Need to understand actual implementation of built-in functions
- Want to see internal sub-functions and their relationships
- Debugging unexpected behavior in built-in functions
- Learning advanced Wolfram Language programming patterns
- Understanding why a function works the way it does
- Tracing execution flow through internal functions

## Procedure

### 1. Make sure you can evaluate Wolfram code

To use this skill, you need to be able to evaluate Wolfram Language code. If you have access to the Wolfram MCP Server, you can run code directly there. Alternatively, you can use `wolframscript` on your command line.

If you have no way to evaluate Wolfram code, inform the user that this skill requires Wolfram code execution.


### 2. Load the DefinitionString Utility
First, load the specialized function for examining symbol definitions:

```wolfram
Get["utils/DefinitionString.wl"]
```

*(The utility file is located in the `utils/` subdirectory of this skill)*

This provides the `DefinitionString` function that:
- Removes ReadProtected attributes to access internal definitions
- Lists the context of the function and its sub-functions
- Aliases long context names for readability (e.g., `Parallel`Kernels`Private`` → `c1``)
- Shows the complete definition structure including attributes and rules
- Any definitions of compiled code can't be fully revealed and will be shown with the placeholder `<<Hidden kernel definitions>>`

### 3. Initial Function Inspection
Use DefinitionString on the target function to see its internal structure:
- Look for main implementation patterns
- Identify key sub-functions being called
- Note any context switching or special handling
- Understand the overall architecture

### 4. Examine the Main Function
Use DefinitionString on the target function to see its internal structure:
- Look for main implementation patterns
- Identify key sub-functions being called
- Note any context switching or special handling
- Understand the overall architecture

### 5. Drill Down Into Sub-Functions
For each important sub-function found in step 3:
- Use the fully qualified symbol name (with full context)
- Apply DefinitionString to reveal deeper implementation
- Continue drilling down until reaching either:
  - Kernel/C-level implementations (no further Wolfram Language code)
  - Simple/atomic operations
  - Sufficient understanding for the user's needs

### 6. Map Function Hierarchy
Build a mental/textual map showing:
- Main function entry point
- Key sub-functions and their roles
- Data flow between components
- Special cases or conditional branches
- Context relationships and dependencies

### 7. Synthesize Understanding
Present findings as:
- **Main Implementation Pattern**: High-level approach used
- **Key Sub-Functions**: Important internal functions and their purposes
- **Execution Flow**: How data moves through the implementation  
- **Special Handling**: Edge cases, optimizations, or unusual patterns
- **Context Dependencies**: External functions or resources used

## Analysis Strategies

### For Built-in Functions
- Many built-ins have Wolfram Language wrapper layers over C/kernel implementations
- Look for argument validation, option processing, and dispatch logic
- Identify where the actual computation happens vs. interface handling

### For Complex Functions  
- Break down into phases (input processing, computation, output formatting)
- Trace through conditional branches based on different argument types
- Identify internal data structures and transformations

### For Performance-Critical Functions
- Look for optimization patterns and special cases
- Identify parallel vs. serial execution paths  
- Note memory management and efficiency techniques

## Example Usage

**Inspect main function:**
```
wolfram-plumbing: Load utility and examine Parallelize implementation
```

**Deep dive into sub-functions:**  
```
wolfram-plumbing: Drill down into doAutolaunch function found in Parallelize analysis
```

**Understand specific behavior:**
```
wolfram-plumbing: Why does ListPlot handle data differently for different input types?
```

## Tips
- Load the DefinitionString utility first with `Get["utils/DefinitionString.wl"]`
- Start with the main function, then drill down systematically
- Use fully qualified symbol names (Context`Symbol) for sub-functions
- Some functions may have multiple implementation paths - trace the relevant one
- Internal functions often have cryptic names - focus on understanding their role
- C/kernel implementations will show minimal Wolfram Language code
- Context aliases help readability but may need translation for drilling down
- Some functions will only have a placeholder definition till they are used for the first time. In that case, trigger the function with a simple call to reveal the full definition.

## Limitations
- Cannot examine kernel-level C implementations
- Some internal functions may be further protected
- Implementation may vary between Wolfram Language versions
- Very large definitions may be overwhelming - focus on key parts