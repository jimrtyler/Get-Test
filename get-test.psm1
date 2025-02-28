# Get-Test.psm1
# A PowerShell module for browsing and taking tests from JSON files

function Get-Test {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$IgnoreTimeLimit
    )

    # Main function to run the test browser
    function Show-TestBrowser {
        # Define base directory for tests
        $testBaseDir = Join-Path (Get-Location) "tests"

        # Check if tests directory exists
        if (-not (Test-Path $testBaseDir)) {
            Write-Error "Tests directory not found at: $testBaseDir"
            return
        }

        # Get list of test categories (subfolders in /tests/)
        $categories = Get-ChildItem -Path $testBaseDir -Directory
        if ($categories.Count -eq 0) {
            Write-Error "No test categories found in $testBaseDir"
            return
        }

        # Prompt user to select a category
        Clear-Host
        Write-Host "Which category of tests would you like to browse?" -ForegroundColor Cyan
        for ($i = 0; $i -lt $categories.Count; $i++) {
            Write-Host "[$($i+1)] $($categories[$i].Name)"
        }
        Write-Host "[q] Quit" -ForegroundColor Yellow

        $categoryChoice = Read-Host "Enter category number"
        
        if ($categoryChoice -eq 'q') {
            return
        }
        
        if (-not ($categoryChoice -match '^\d+$') -or [int]$categoryChoice -lt 1 -or [int]$categoryChoice -gt $categories.Count) {
            Write-Host "Invalid selection. Press Enter to try again." -ForegroundColor Red
            Read-Host
            Show-TestBrowser
            return
        }

        $selectedCategory = $categories[[int]$categoryChoice - 1]
        $categoryPath = $selectedCategory.FullName

        # Check if the selected category has subdirectories
        $subcategories = Get-ChildItem -Path $categoryPath -Directory
        
        if ($subcategories.Count -gt 0) {
            Show-SubcategoryMenu -SubCategories $subcategories -CategoryPath $categoryPath
        } else {
            # If no subcategories, use the category path
            Show-TestFiles -Path $categoryPath
        }
    }

    # Function to show subcategory menu
    function Show-SubcategoryMenu {
        param (
            [array]$SubCategories,
            [string]$CategoryPath
        )
        
        # Prompt user to select a subcategory
        Clear-Host
        Write-Host "Which subcategory would you like to browse?" -ForegroundColor Cyan
        for ($i = 0; $i -lt $SubCategories.Count; $i++) {
            Write-Host "[$($i+1)] $($SubCategories[$i].Name)"
        }
        Write-Host "[b] Back to categories" -ForegroundColor Yellow
        Write-Host "[q] Quit" -ForegroundColor Yellow

        $subCategoryChoice = Read-Host "Enter subcategory number"
        
        if ($subCategoryChoice -eq 'b') {
            Show-TestBrowser
            return
        }
        
        if ($subCategoryChoice -eq 'q') {
            return
        }
        
        if (-not ($subCategoryChoice -match '^\d+$') -or [int]$subCategoryChoice -lt 1 -or [int]$subCategoryChoice -gt $SubCategories.Count) {
            Write-Host "Invalid selection. Press Enter to try again." -ForegroundColor Red
            Read-Host
            Show-SubcategoryMenu -SubCategories $SubCategories -CategoryPath $CategoryPath
            return
        }

        $selectedSubCategory = $SubCategories[[int]$subCategoryChoice - 1]
        Show-TestFiles -Path $selectedSubCategory.FullName
    }

    # Function to show test files
    function Show-TestFiles {
        param (
            [string]$Path
        )
        
        # Get list of JSON test files
        $testFiles = Get-ChildItem -Path $Path -Filter "*.json"
        
        if ($testFiles.Count -eq 0) {
            Write-Host "No JSON test files found in selected path: $Path" -ForegroundColor Red
            Write-Host "Press Enter to go back" -ForegroundColor Yellow
            Read-Host
            # Go back to previous menu
            if ((Get-ChildItem -Path (Split-Path $Path -Parent) -Directory).Count -gt 0) {
                Show-TestBrowser
            } else {
                Show-SubcategoryMenu -SubCategories (Get-ChildItem -Path (Split-Path $Path -Parent) -Directory) -CategoryPath (Split-Path (Split-Path $Path -Parent) -Parent)
            }
            return
        }

        # Prompt user to select a test file
        Clear-Host
        Write-Host "Which test would you like to take?" -ForegroundColor Cyan
        
        # Create an array to store test info for each file
        $testInfoArray = @()
        
        for ($i = 0; $i -lt $testFiles.Count; $i++) {
            try {
                # Read the file to get the test name
                $testContent = Get-Content -Path $testFiles[$i].FullName -Raw | ConvertFrom-Json
                
                # Check if test has a name field
                if ($testContent.PSObject.Properties.Name -contains "name") {
                    $testName = $testContent.name
                } else {
                    $testName = $testFiles[$i].BaseName
                }
                
                # Get question count if available
                if ($testContent.PSObject.Properties.Name -contains "questionCount") {
                    $questionCount = $testContent.questionCount
                } elseif ($testContent.questions -is [array]) {
                    $questionCount = $testContent.questions.Count
                } else {
                    $questionCount = "Unknown"
                }
                
                # Get time limit if available
                if ($testContent.PSObject.Properties.Name -contains "timeLimit") {
                    $timeLimit = "$($testContent.timeLimit) minutes"
                } else {
                    $timeLimit = "No limit"
                }
                
                # Add to the array
                $testInfoArray += [PSCustomObject]@{
                    Index = $i
                    FileName = $testFiles[$i].Name
                    Name = $testName
                    QuestionCount = $questionCount
                    TimeLimit = $timeLimit
                }
                
                # Display test info
                Write-Host "[$($i+1)] $testName - Questions: $questionCount, Time: $timeLimit"
                
            } catch {
                # If we can't read the file properly, just show the filename
                Write-Host "[$($i+1)] $($testFiles[$i].BaseName) [Unable to read file details]"
                $testInfoArray += [PSCustomObject]@{
                    Index = $i
                    FileName = $testFiles[$i].Name
                    Name = $testFiles[$i].BaseName
                    QuestionCount = "Unknown"
                    TimeLimit = "Unknown"
                }
            }
        }
        
        Write-Host "[b] Back" -ForegroundColor Yellow
        Write-Host "[q] Quit" -ForegroundColor Yellow
        
        $testChoice = Read-Host "Enter test number"
        
        if ($testChoice -eq 'b') {
            # Go back to previous menu
            if ((Get-ChildItem -Path (Split-Path $Path -Parent) -Directory).Count -gt 0) {
                Show-SubcategoryMenu -SubCategories (Get-ChildItem -Path (Split-Path $Path -Parent) -Directory) -CategoryPath (Split-Path (Split-Path $Path -Parent) -Parent)
            } else {
                Show-TestBrowser
            }
            return
        }
        
        if ($testChoice -eq 'q') {
            return
        }
        
        if (-not ($testChoice -match '^\d+$') -or [int]$testChoice -lt 1 -or [int]$testChoice -gt $testFiles.Count) {
            Write-Host "Invalid selection. Press Enter to try again." -ForegroundColor Red
            Read-Host
            Show-TestFiles -Path $Path
            return
        }

        $selectedTest = $testFiles[[int]$testChoice - 1]
        Start-Test -TestFilePath $selectedTest.FullName
    }

    # Function to update and display remaining time
    function Update-TimeRemaining {
        param (
            [DateTime]$TimeExpires
        )
        
        $currentTime = Get-Date
        return $TimeExpires - $currentTime
    }

    # Function to start a test
    function Start-Test {
        param (
            [string]$TestFilePath
        )
        
        # Load and parse the selected JSON test file
        try {
            $testContent = Get-Content -Path $TestFilePath -Raw | ConvertFrom-Json
        } catch {
            Write-Error "Failed to parse the JSON test file: $_"
            Read-Host "Press Enter to go back"
            Show-TestBrowser
            return
        }

        # Check if the test contains required fields
        if ($testContent.PSObject.Properties.Name -contains "questions") {
            # New format with metadata
            $testName = if ($testContent.PSObject.Properties.Name -contains "name") { $testContent.name } else { (Get-Item $TestFilePath).BaseName }
            $testQuestions = $testContent.questions
            $timeLimit = if ($testContent.PSObject.Properties.Name -contains "timeLimit") { $testContent.timeLimit } else { 0 }
        } else {
            # Legacy format where the content is directly an array of questions
            $testName = (Get-Item $TestFilePath).BaseName
            $testQuestions = $testContent
            $timeLimit = 0
        }

        # Validate questions format
        if (-not ($testQuestions -is [array])) {
            Write-Error "Invalid test format. The JSON file should contain an array of question objects."
            Read-Host "Press Enter to go back"
            Show-TestBrowser
            return
        }

        # Create arrays to store user responses and correct answers
        $userResponses = @()
        $correctAnswers = @()
        
        # Administer the test
        $totalQuestions = $testQuestions.Count
        $score = 0
        
        # Set up timer if time limit is specified
        $timerEnabled = $timeLimit -gt 0 -and -not $IgnoreTimeLimit
        $timeStarted = Get-Date
        $timeExpires = $timeStarted.AddMinutes($timeLimit)

        # Display test info
        Clear-Host
        Write-Host "Test: $testName" -ForegroundColor Cyan
        Write-Host "Questions: $totalQuestions" -ForegroundColor Cyan
        if ($timerEnabled) {
            Write-Host "Time Limit: $timeLimit minutes (ends at $($timeExpires.ToString('hh:mm:ss tt')))" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "[b] Back to test selection" -ForegroundColor Yellow
        Write-Host "[q] Quit" -ForegroundColor Yellow
        Write-Host ""
        
        $startChoice = Read-Host "Press Enter to begin the test, or b to go back"
        
        if ($startChoice -eq 'b') {
            Show-TestFiles -Path (Split-Path $TestFilePath -Parent)
            return
        }
        
        if ($startChoice -eq 'q') {
            return
        }
        
        for ($questionIndex = 0; $questionIndex -lt $totalQuestions; $questionIndex++) {
            $question = $testQuestions[$questionIndex]
            
            # Check time limit if enabled
            if ($timerEnabled) {
                $timeRemaining = Update-TimeRemaining -TimeExpires $timeExpires
                if ($timeRemaining.TotalSeconds -le 0) {
                    Write-Host "Time expired!" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    break
                }
            }
            
            # Validate question format
            if (-not (($question.PSObject.Properties.Name -contains "question") -and 
                     ($question.PSObject.Properties.Name -contains "options") -and 
                     ($question.PSObject.Properties.Name -contains "answer"))) {
                Write-Host "Question #$($questionIndex + 1) has invalid format. Skipping..." -ForegroundColor Yellow
                continue
            }
            
            # Store correct answer
            $correctAnswers += $question.answer
            
            $answerSubmitted = $false
            
            while (-not $answerSubmitted) {
                # Display question
                Clear-Host
                Write-Host "Question $($questionIndex + 1) of $totalQuestions" -ForegroundColor Cyan
                
                # Display live timer if enabled
                if ($timerEnabled) {
                    $timeRemaining = Update-TimeRemaining -TimeExpires $timeExpires
                    if ($timeRemaining.TotalSeconds -le 0) {
                        Write-Host "TIME EXPIRED!" -ForegroundColor Red
                        Start-Sleep -Seconds 2
                        $answerSubmitted = $true
                        break
                    }
                    
                    $remainingMinutes = [math]::Floor($timeRemaining.TotalMinutes)
                    $remainingSeconds = [math]::Floor($timeRemaining.TotalSeconds % 60)
                    Write-Host "Time Remaining: $($remainingMinutes.ToString('00')):$($remainingSeconds.ToString('00'))" -ForegroundColor Yellow
                }
                
                Write-Host ""
                Write-Host $question.question -ForegroundColor White
                Write-Host ""
                
                # Display options
                for ($i = 0; $i -lt $question.options.Count; $i++) {
                    Write-Host "[$($i+1)] $($question.options[$i])"
                }
                
                Write-Host ""
                Write-Host "[b] Back to previous question" -ForegroundColor Yellow
                Write-Host "[s] Skip this question" -ForegroundColor Yellow
                
                # Get user answer
                $userAnswer = Read-Host "Enter your answer"
                
                if ($userAnswer -eq 'b' -and $questionIndex -gt 0) {
                    # Go back to previous question
                    $questionIndex -= 2  # Will be incremented in the loop
                    $userResponses = $userResponses[0..($userResponses.Count-2)]
                    $answerSubmitted = $true
                    continue
                }
                
                if ($userAnswer -eq 's') {
                    # Skip this question (mark as unanswered)
                    $userResponses += -1
                    $answerSubmitted = $true
                    continue
                }
                
                # Validate user input
                if (-not ($userAnswer -match '^\d+$') -or [int]$userAnswer -lt 1 -or [int]$userAnswer -gt $question.options.Count) {
                    Write-Host "Invalid input. Please enter a number between 1 and $($question.options.Count)." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                    continue
                }
                
                # Store user response (convert to 0-based for internal storage)
                $userResponses += ([int]$userAnswer - 1)
                
                # Check if the answer is correct (but don't display feedback)
                if (([int]$userAnswer - 1) -eq $question.answer) {
                    $score++
                }
                
                $answerSubmitted = $true
            }
            
            # Check if time expired during the last question
            if ($timerEnabled) {
                $timeRemaining = Update-TimeRemaining -TimeExpires $timeExpires
                if ($timeRemaining.TotalSeconds -le 0) {
                    break
                }
            }
        }
        
        # Calculate time taken
        $timeFinished = Get-Date
        $timeElapsed = $timeFinished - $timeStarted
        $minutesTaken = [math]::Floor($timeElapsed.TotalMinutes)
        $secondsTaken = [math]::Floor($timeElapsed.TotalSeconds % 60)
        
        # Calculate percentage score
        $percentScore = [math]::Round(($score / $totalQuestions) * 100, 2)
        $questionsAnswered = $userResponses.Count
        
        # Display results
        Clear-Host
        Write-Host "Test Results: $testName" -ForegroundColor Cyan
        Write-Host ""
        
        if ($timerEnabled -and $timeFinished -gt $timeExpires) {
            Write-Host "TIME EXPIRED - Test not fully completed!" -ForegroundColor Red
            $percentAnswered = [math]::Round(($questionsAnswered / $totalQuestions) * 100, 2)
            Write-Host "Questions Answered: $questionsAnswered out of $totalQuestions ($percentAnswered%)" -ForegroundColor Yellow
        }
        
        Write-Host "Your Score: $score out of $totalQuestions ($percentScore%)" -ForegroundColor Yellow
        Write-Host "Time Taken: $minutesTaken minutes and $secondsTaken seconds" -ForegroundColor Yellow
        
        # Provide feedback based on score
        if ($percentScore -ge 90) {
            Write-Host "Excellent work!" -ForegroundColor Green
        } elseif ($percentScore -ge 70) {
            Write-Host "Good job!" -ForegroundColor Green
        } elseif ($percentScore -ge 50) {
            Write-Host "You passed, but there's room for improvement." -ForegroundColor Yellow
        } else {
            Write-Host "You might want to study more and try again." -ForegroundColor Red
        }
        
        Write-Host ""
        Write-Host "Press Enter to return to main menu" -ForegroundColor Yellow
        Read-Host
        
        # Return to main menu
        Show-TestBrowser
    }
    
    # Start the main menu
    Show-TestBrowser
}

# Export the function
Export-ModuleMember -Function Get-Test