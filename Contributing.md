Contributing to FinTrack
Thank you for your interest in contributing to FinTrack!. We welcome contributions from developers of all skill levels. This guide will help you get started.

How to Contribute
1. Fork and Clone
Fork the repository on GitHub
Clone your fork locally:
git clone https://github.com/Prateek9876/NagarVikas
cd nagarvikas
2. Set Up Development Environment
Install Node.js (version 16 or higher)
Install dependencies:
npm install
Create a .env file with the required environment variables see .env.example
Start the development server:
npm run dev
3. Create a Branch
Create a new branch for your feature or bug fix:

git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
Types of Contributions
🐛 Bug Fixes
Look for issues labeled bug or good first issue
Include steps to reproduce the bug in your PR description
Add tests if applicable
✨ New Features
Check existing issues or create a new issue to discuss the feature
Follow the existing code patterns and architecture
Update documentation as needed
📚 Documentation
Improve README.md, code comments, or inline documentation
Add examples and use cases
Fix typos and grammar issues
🎨 UI/UX Improvements
Look for issues labeled design-needed or ui/ux
Ensure changes are responsive and accessible
Follow the existing Tailwind CSS patterns
🧪 Testing
Add unit tests for new features
Improve test coverage
Fix failing tests
Code Style Guidelines
JavaScript/React
Use functional components with hooks
Follow ESLint rules (run npm run lint)
Use descriptive variable and function names
Add comments for complex logic
CSS/Styling
Use Tailwind CSS classes
Follow mobile-first responsive design
Maintain consistent spacing and typography
File Structure
Place components in appropriate directories
Use clear, descriptive file names
Keep components small and focused
Commit Message Guidelines
Use clear and descriptive commit messages:

feat: add expense category filtering
fix: resolve Firebase authentication bug
docs: update installation instructions
style: improve dashboard responsive design
test: add unit tests for expense calculations
Types:

feat: New feature
fix: Bug fix
docs: Documentation
style: UI/UX changes
test: Adding tests
refactor: Code refactoring
Pull Request Process
Before Submitting
Test your changes thoroughly
Run npm run lint and fix any issues
Update documentation if needed
Ensure your branch is up to date with main
Include a screenshot or screen recording of your changes when submitting a PR. This helps us review and merge your work more efficiently.
PR Description Template
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] UI/UX improvement

## Testing
- [ ] Tested locally
- [ ] No console errors
- [ ] Responsive design verified

## Screenshots (if applicable)
Add screenshots for UI changes

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
Review Process
Maintainers will review your PR
Address any requested changes
Once approved, your PR will be merged
Issue Guidelines
Reporting Bugs
Use the following template:

**Bug Description**
A clear description of the bug

**Steps to Reproduce**
1. Go to '...'
2. Click on '...'
3. See error

**Expected Behavior**
What should happen

**Screenshots**
If applicable

**Environment**
- OS: [e.g., Windows, macOS, Linux]
- Browser: [e.g., Chrome, Firefox]
- Version: [e.g., 22]
Feature Requests
**Feature Description**
Clear description of the proposed feature

**Problem it Solves**
What problem does this solve?

**Proposed Solution**
How should this be implemented?

**Additional Context**
Any other relevant information
Development Tips
Firebase Configuration
Never commit API keys or sensitive data
Test with your own Firebase project during development
Ensure Firebase security rules are followed
AI Features
Test AI chatbot responses thoroughly
Ensure voice AI integration works across devices
Handle API failures gracefully
Performance
Optimize chart rendering for large datasets
Implement proper loading states
Use React.memo for expensive components
Getting Help
Check existing issues and documentation first
Ask questions in GitHub issues
Code of Conduct
Please read and follow our Code of Conduct.

Thank you for contributing to NagarVikas! Your contributions help make personal finance management accessible to everyone.