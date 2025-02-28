# Get-Test

A flexible, extensible testing application with support for multiple choice questions, timed tests, and a structured directory-based organization system.

![Test Browser Screenshot](https://via.placeholder.com/800x450.png?text=Test+Browser+Screenshot)

## Features

- **Multiple Interfaces**: CLI, GUI, and web-based implementations available
- **Organized Test Structure**: Categories and subcategories for organized test management
- **Timed Tests**: Optional time limits with countdown timer
- **Navigation Options**: Back buttons, skip questions, previous/next navigation
- **No Immediate Feedback**: Focus on completing the test before seeing results
- **Compatible JSON Format**: Use the same test files across all implementations

## Installation

### PowerShell CLI Version
```powershell
# Clone the repository
git clone https://github.com/yourusername/test-browser.git
cd test-browser

# Run the CLI version
Import-Module .\Get-Test.ps1
Get-Test
```

### PowerShell GUI Version
```powershell
# Run the GUI version
.\Get-Test-GUI.ps1
```

### Web Version
```
# Serve the web version from any web server
# Example with Python's built-in server:
python -m http.server
# Then navigate to http://localhost:8000
```

## Directory Structure

Tests are organized in a `/tests/` directory with the following structure:
```
/tests/
├── category1/
│   ├── test1.json
│   ├── test2.json
│   └── subcategory/
│       ├── test3.json
│       └── test4.json
├── category2/
│   └── test5.json
└── category3/
    └── subcategory/
        └── test6.json
```

## JSON Test Format

Tests use a standard JSON format:

```json
{
  "name": "Sample Test",
  "questionCount": 3,
  "timeLimit": 10,
  "questions": [
    {
      "question": "What is the primary function of DNS?",
      "options": [
        "To assign IP addresses to devices",
        "To translate domain names to IP addresses",
        "To encrypt network traffic",
        "To filter unwanted traffic"
      ],
      "answer": 1
    },
    {
      "question": "Which port is commonly used for HTTPS traffic?",
      "options": ["21", "22", "80", "443"],
      "answer": 3
    },
    {
      "question": "What does CIDR stand for?",
      "options": [
        "Classless Inter-Domain Routing",
        "Connection Identifier Domain Registry",
        "Central Internet Data Repository",
        "Concurrent IP Data Relay"
      ],
      "answer": 0
    }
  ]
}
```

- **name**: Display name for the test
- **questionCount**: Number of questions (optional, calculated from questions array if not provided)
- **timeLimit**: Time limit in minutes (0 or omitted for no time limit)
- **questions**: Array of question objects
  - **question**: The question text
  - **options**: Array of possible answers
  - **answer**: Zero-based index of the correct answer

## Usage

### CLI Version
```powershell
# Start the test browser
Get-Test

# Run with time limits disabled
Get-Test -IgnoreTimeLimit
```

### GUI Version
1. Run `.\Get-Test-GUI.ps1`
2. Browse the test categories
3. Select a test file
4. Click 'Start Test' to begin
5. Optional: Check 'Ignore Time Limit' to disable time limits

### Web Version
1. Open the HTML file in a web browser
2. Browse categories and tests
3. Follow the on-screen instructions

## Screenshots

### CLI Version
```
Select a test category to begin:
[1] aws
[2] microsoft
[3] comptia

Enter category number: 3
```

### GUI Version
![GUI Version](https://via.placeholder.com/400x300.png?text=GUI+Version)

### Web Version
![Web Version](https://via.placeholder.com/400x300.png?text=Web+Version)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Roadmap

- [ ] Add support for different question types (fill-in-the-blank, matching, etc.)
- [ ] Implement scoring algorithms with weighted questions
- [ ] Add reporting and progress tracking
- [ ] Create an admin interface for test creation

## Connect

Follow the creator for more PowerShell content:

[![YouTube Channel](https://img.shields.io/badge/YouTube-PowerShell%20Engineer-red?style=for-the-badge&logo=youtube)](https://youtube.com/@PowerShellEngineer)

## License

This project is licensed under the MIT License - see the LICENSE file for details.
