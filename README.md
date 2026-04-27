# LLM-Skills

A curated collection of specialized skills for Large Language Model (LLM) agents, focused on Wolfram Language development workflows.

## Overview

This repository contains thoroughly tested agent skills that enhance LLM capabilities in specialized domains. For general information about agent skills and their structure, visit [agentskills.io](https://agentskills.io/home).

## Skills in this Repository

### 🔧 wolfram-plumbing
**Domain**: Wolfram Language Development  
**Purpose**: Examine internal implementations of Wolfram Language built-in functions when documentation is insufficient

**Key Capabilities**:
- Reveal actual function definitions using the `DefinitionString` utility
- Expose internal sub-functions and implementation patterns
- Map function hierarchies and execution flows
- Debug unexpected behavior in built-in functions
- Learn advanced Wolfram Language programming patterns

**When to Use**:
- Official Wolfram documentation lacks implementation details
- Need to understand why a built-in function behaves a certain way
- Debugging complex interactions with built-in functions
- Learning advanced programming patterns from Wolfram's implementations

## Repository Structure

```
LLM-Skills/
├── README.md                    # This file
├── LICENSE                      # MIT License
└── wolfram-plumbing/           # Wolfram Language function inspection skill
    ├── SKILL.md                # Main skill instructions and workflows
    ├── example-parallelize.md  # Detailed example using Parallelize function
    └── utils/                  # Supporting utilities
        └── DefinitionString.wl # Wolfram Language utility for function inspection
```

## Using These Skills

### Integration with LLM Agents

1. **Copy the skill directory** into your agent's skills folder
2. **Configure your agent** to load the skill when working with Wolfram Language
3. **Test with the provided examples** to ensure proper integration

### Manual Usage

Follow the procedures in each `SKILL.md` file. All skills are self-contained with necessary utilities and examples included.

### Prerequisites

**For wolfram-plumbing skill**:
- Access to Wolfram Language evaluation (Mathematica, Wolfram Engine, or Wolfram MCP Server)
- Ability to execute Wolfram Language code in your environment

## Contributing

We welcome contributions of new skills and improvements to existing ones! 

### Contributing a New Skill

1. **Fork this repository**
2. **Create a new directory** for your skill following the naming convention: `domain-name/`
3. **Include the required files**:
   - `SKILL.md` - Main skill instructions with proper YAML frontmatter
   - `example-*.md` - At least one detailed example
   - `utils/` - Any supporting utilities or code
4. **Test thoroughly** to ensure the skill works reliably
5. **Submit a pull request** with a clear description

### Skill Quality Standards

- **Clear trigger conditions**: When should this skill be used?
- **Step-by-step procedures**: Detailed, actionable workflows  
- **Complete examples**: Real-world usage with expected outputs
- **Error handling**: Guidance for common failure modes
- **Dependencies**: Clear documentation of requirements

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Related Projects

- [VS Code Agent Skills](https://github.com/microsoft/vscode) - Skills for VS Code development workflows
- [LangChain Tools](https://github.com/langchain-ai/langchain) - Broader ecosystem of LLM tools and utilities

## Acknowledgments

Skills in this repository are developed and tested by the community. Each skill includes attribution to its original authors and contributors.

---

*Building better AI agents through specialized, reusable skills* 🚀

