# PowerShell GUI Test Browser
# This script creates a Windows Forms application for browsing and taking tests from JSON files

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Global variables
$global:currentPath = @()
$global:currentTestData = $null
$global:userAnswers = @()
$global:currentQuestionIndex = 0
$global:testTimer = $null
$global:testTimeLimit = 0
$global:testStartTime = $null
$global:selectedOption = $null

# Create main form
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Test Browser"
$mainForm.Size = New-Object System.Drawing.Size(800, 600)
$mainForm.StartPosition = "CenterScreen"
$mainForm.FormBorderStyle = "FixedDialog"
$mainForm.MaximizeBox = $false
$mainForm.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# Create panels for different views
$categoriesPanel = New-Object System.Windows.Forms.Panel
$categoriesPanel.Dock = "Fill"
$categoriesPanel.Visible = $true

$subcategoriesPanel = New-Object System.Windows.Forms.Panel
$subcategoriesPanel.Dock = "Fill"
$subcategoriesPanel.Visible = $false

$testsPanel = New-Object System.Windows.Forms.Panel
$testsPanel.Dock = "Fill"
$testsPanel.Visible = $false

$testInfoPanel = New-Object System.Windows.Forms.Panel
$testInfoPanel.Dock = "Fill"
$testInfoPanel.Visible = $false

$testPanel = New-Object System.Windows.Forms.Panel
$testPanel.Dock = "Fill"
$testPanel.Visible = $false

$resultsPanel = New-Object System.Windows.Forms.Panel
$resultsPanel.Dock = "Fill"
$resultsPanel.Visible = $false

# Add panels to form
$mainForm.Controls.Add($categoriesPanel)
$mainForm.Controls.Add($subcategoriesPanel)
$mainForm.Controls.Add($testsPanel)
$mainForm.Controls.Add($testInfoPanel)
$mainForm.Controls.Add($testPanel)
$mainForm.Controls.Add($resultsPanel)

# Categories Panel Controls
$categoriesLabel = New-Object System.Windows.Forms.Label
$categoriesLabel.Text = "Select a test category to begin:"
$categoriesLabel.Location = New-Object System.Drawing.Point(20, 20)
$categoriesLabel.Size = New-Object System.Drawing.Size(760, 30)
$categoriesLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$categoriesPanel.Controls.Add($categoriesLabel)

$categoriesListBox = New-Object System.Windows.Forms.ListBox
$categoriesListBox.Location = New-Object System.Drawing.Point(20, 60)
$categoriesListBox.Size = New-Object System.Drawing.Size(740, 450)
$categoriesListBox.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$categoriesListBox.Add_DoubleClick({
    if ($categoriesListBox.SelectedItem) {
        SelectCategory $categoriesListBox.SelectedItem
    }
})
$categoriesPanel.Controls.Add($categoriesListBox)

# Subcategories Panel Controls
$subcategoriesTitleLabel = New-Object System.Windows.Forms.Label
$subcategoriesTitleLabel.Text = "Subcategories"
$subcategoriesTitleLabel.Location = New-Object System.Drawing.Point(20, 20)
$subcategoriesTitleLabel.Size = New-Object System.Drawing.Size(760, 30)
$subcategoriesTitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$subcategoriesPanel.Controls.Add($subcategoriesTitleLabel)

$subcategoriesListBox = New-Object System.Windows.Forms.ListBox
$subcategoriesListBox.Location = New-Object System.Drawing.Point(20, 60)
$subcategoriesListBox.Size = New-Object System.Drawing.Size(740, 450)
$subcategoriesListBox.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$subcategoriesListBox.Add_DoubleClick({
    if ($subcategoriesListBox.SelectedItem) {
        SelectSubcategory $subcategoriesListBox.SelectedItem
    }
})
$subcategoriesPanel.Controls.Add($subcategoriesListBox)

$backToCategoriesButton = New-Object System.Windows.Forms.Button
$backToCategoriesButton.Text = "Back to Categories"
$backToCategoriesButton.Location = New-Object System.Drawing.Point(20, 520)
$backToCategoriesButton.Size = New-Object System.Drawing.Size(150, 30)
$backToCategoriesButton.Add_Click({ ShowCategoriesView })
$subcategoriesPanel.Controls.Add($backToCategoriesButton)

# Tests Panel Controls
$testsTitleLabel = New-Object System.Windows.Forms.Label
$testsTitleLabel.Text = "Available Tests"
$testsTitleLabel.Location = New-Object System.Drawing.Point(20, 20)
$testsTitleLabel.Size = New-Object System.Drawing.Size(760, 30)
$testsTitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$testsPanel.Controls.Add($testsTitleLabel)

$testsListBox = New-Object System.Windows.Forms.ListBox
$testsListBox.Location = New-Object System.Drawing.Point(20, 60)
$testsListBox.Size = New-Object System.Drawing.Size(740, 450)
$testsListBox.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$testsListBox.Add_DoubleClick({
    if ($testsListBox.SelectedItem) {
        $selectedTestName = $testsListBox.SelectedItem.ToString().Split(' - ')[0]
        SelectTest $selectedTestName
    }
})
$testsPanel.Controls.Add($testsListBox)

$backFromTestsButton = New-Object System.Windows.Forms.Button
$backFromTestsButton.Text = "Back"
$backFromTestsButton.Location = New-Object System.Drawing.Point(20, 520)
$backFromTestsButton.Size = New-Object System.Drawing.Size(150, 30)
$backFromTestsButton.Add_Click({ HandleBackFromTests })
$testsPanel.Controls.Add($backFromTestsButton)

# Test Info Panel Controls
$testInfoTitleLabel = New-Object System.Windows.Forms.Label
$testInfoTitleLabel.Text = "Test Information"
$testInfoTitleLabel.Location = New-Object System.Drawing.Point(20, 20)
$testInfoTitleLabel.Size = New-Object System.Drawing.Size(760, 30)
$testInfoTitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$testInfoPanel.Controls.Add($testInfoTitleLabel)

$testInfoContentLabel = New-Object System.Windows.Forms.Label
$testInfoContentLabel.Location = New-Object System.Drawing.Point(20, 60)
$testInfoContentLabel.Size = New-Object System.Drawing.Size(740, 400)
$testInfoContentLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$testInfoPanel.Controls.Add($testInfoContentLabel)

$backFromTestInfoButton = New-Object System.Windows.Forms.Button
$backFromTestInfoButton.Text = "Back"
$backFromTestInfoButton.Location = New-Object System.Drawing.Point(20, 520)
$backFromTestInfoButton.Size = New-Object System.Drawing.Size(150, 30)
$backFromTestInfoButton.Add_Click({ HandleBackFromTestInfo })
$testInfoPanel.Controls.Add($backFromTestInfoButton)

$startTestButton = New-Object System.Windows.Forms.Button
$startTestButton.Text = "Start Test"
$startTestButton.Location = New-Object System.Drawing.Point(610, 520)
$startTestButton.Size = New-Object System.Drawing.Size(150, 30)
$startTestButton.Add_Click({ StartTest })
$testInfoPanel.Controls.Add($startTestButton)

# Test Panel Controls
$timerPanel = New-Object System.Windows.Forms.Panel
$timerPanel.Location = New-Object System.Drawing.Point(20, 20)
$timerPanel.Size = New-Object System.Drawing.Size(740, 40)
$timerPanel.BorderStyle = "FixedSingle"
$testPanel.Controls.Add($timerPanel)

$timerQuestionLabel = New-Object System.Windows.Forms.Label
$timerQuestionLabel.Text = "Question 1 of 10"
$timerQuestionLabel.Location = New-Object System.Drawing.Point(10, 10)
$timerQuestionLabel.Size = New-Object System.Drawing.Size(200, 20)
$timerQuestionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$timerPanel.Controls.Add($timerQuestionLabel)

$timerCountdownLabel = New-Object System.Windows.Forms.Label
$timerCountdownLabel.Text = "Time Remaining: 00:00"
$timerCountdownLabel.TextAlign = "MiddleRight"
$timerCountdownLabel.Location = New-Object System.Drawing.Point(400, 10)
$timerCountdownLabel.Size = New-Object System.Drawing.Size(330, 20)
$timerCountdownLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$timerPanel.Controls.Add($timerCountdownLabel)

$questionPanel = New-Object System.Windows.Forms.Panel
$questionPanel.Location = New-Object System.Drawing.Point(20, 70)
$questionPanel.Size = New-Object System.Drawing.Size(740, 380)
$questionPanel.BorderStyle = "FixedSingle"
$testPanel.Controls.Add($questionPanel)

$questionTextLabel = New-Object System.Windows.Forms.Label
$questionTextLabel.Location = New-Object System.Drawing.Point(10, 10)
$questionTextLabel.Size = New-Object System.Drawing.Size(720, 60)
$questionTextLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$questionPanel.Controls.Add($questionTextLabel)

$optionsPanel = New-Object System.Windows.Forms.Panel
$optionsPanel.Location = New-Object System.Drawing.Point(10, 80)
$optionsPanel.Size = New-Object System.Drawing.Size(720, 290)
$optionsPanel.AutoScroll = $true
$questionPanel.Controls.Add($optionsPanel)

$navigationPanel = New-Object System.Windows.Forms.Panel
$navigationPanel.Location = New-Object System.Drawing.Point(20, 460)
$navigationPanel.Size = New-Object System.Drawing.Size(740, 40)
$testPanel.Controls.Add($navigationPanel)

$prevQuestionButton = New-Object System.Windows.Forms.Button
$prevQuestionButton.Text = "Previous"
$prevQuestionButton.Location = New-Object System.Drawing.Point(0, 5)
$prevQuestionButton.Size = New-Object System.Drawing.Size(100, 30)
$prevQuestionButton.Add_Click({ ShowPreviousQuestion })
$navigationPanel.Controls.Add($prevQuestionButton)

$skipQuestionButton = New-Object System.Windows.Forms.Button
$skipQuestionButton.Text = "Skip"
$skipQuestionButton.Location = New-Object System.Drawing.Point(320, 5)
$skipQuestionButton.Size = New-Object System.Drawing.Size(100, 30)
$skipQuestionButton.Add_Click({ SkipQuestion })
$navigationPanel.Controls.Add($skipQuestionButton)

$nextQuestionButton = New-Object System.Windows.Forms.Button
$nextQuestionButton.Text = "Next"
$nextQuestionButton.Location = New-Object System.Drawing.Point(640, 5)
$nextQuestionButton.Size = New-Object System.Drawing.Size(100, 30)
$nextQuestionButton.Add_Click({ ShowNextQuestion })
$navigationPanel.Controls.Add($nextQuestionButton)

$quitTestButton = New-Object System.Windows.Forms.Button
$quitTestButton.Text = "Quit Test"
$quitTestButton.Location = New-Object System.Drawing.Point(20, 520)
$quitTestButton.Size = New-Object System.Drawing.Size(150, 30)
$quitTestButton.Add_Click({ ConfirmQuitTest })
$testPanel.Controls.Add($quitTestButton)

# Results Panel Controls
$resultsTitleLabel = New-Object System.Windows.Forms.Label
$resultsTitleLabel.Text = "Test Results"
$resultsTitleLabel.Location = New-Object System.Drawing.Point(20, 20)
$resultsTitleLabel.Size = New-Object System.Drawing.Size(760, 30)
$resultsTitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$resultsPanel.Controls.Add($resultsTitleLabel)

$scorePanel = New-Object System.Windows.Forms.Panel
$scorePanel.Location = New-Object System.Drawing.Point(20, 60)
$scorePanel.Size = New-Object System.Drawing.Size(740, 400)
$scorePanel.BorderStyle = "FixedSingle"
$resultsPanel.Controls.Add($scorePanel)

$scorePercentLabel = New-Object System.Windows.Forms.Label
$scorePercentLabel.Text = "85%"
$scorePercentLabel.TextAlign = "MiddleCenter"
$scorePercentLabel.Location = New-Object System.Drawing.Point(270, 40)
$scorePercentLabel.Size = New-Object System.Drawing.Size(200, 80)
$scorePercentLabel.Font = New-Object System.Drawing.Font("Segoe UI", 36, [System.Drawing.FontStyle]::Bold)
$scorePanel.Controls.Add($scorePercentLabel)

$scoreDetailLabel = New-Object System.Windows.Forms.Label
$scoreDetailLabel.Text = "17 out of 20 correct"
$scoreDetailLabel.TextAlign = "MiddleCenter"
$scoreDetailLabel.Location = New-Object System.Drawing.Point(220, 130)
$scoreDetailLabel.Size = New-Object System.Drawing.Size(300, 30)
$scoreDetailLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$scorePanel.Controls.Add($scoreDetailLabel)

$timeDetailLabel = New-Object System.Windows.Forms.Label
$timeDetailLabel.Text = "Time: 5:42"
$timeDetailLabel.TextAlign = "MiddleCenter"
$timeDetailLabel.Location = New-Object System.Drawing.Point(220, 170)
$timeDetailLabel.Size = New-Object System.Drawing.Size(300, 30)
$timeDetailLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$scorePanel.Controls.Add($timeDetailLabel)

$scoreFeedbackLabel = New-Object System.Windows.Forms.Label
$scoreFeedbackLabel.Text = "Good job!"
$scoreFeedbackLabel.TextAlign = "MiddleCenter"
$scoreFeedbackLabel.Location = New-Object System.Drawing.Point(120, 220)
$scoreFeedbackLabel.Size = New-Object System.Drawing.Size(500, 40)
$scoreFeedbackLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$scorePanel.Controls.Add($scoreFeedbackLabel)

$returnToMainButton = New-Object System.Windows.Forms.Button
$returnToMainButton.Text = "Return to Main Menu"
$returnToMainButton.Location = New-Object System.Drawing.Point(270, 300)
$returnToMainButton.Size = New-Object System.Drawing.Size(200, 40)
$returnToMainButton.Add_Click({ ShowCategoriesView })
$scorePanel.Controls.Add($returnToMainButton)

# Function to load test categories
function LoadTestCategories {
    # Get all directories inside the tests folder
    $testBaseDir = Join-Path (Get-Location) "tests"
    
    if (-not (Test-Path $testBaseDir)) {
        [System.Windows.Forms.MessageBox]::Show("Tests directory not found at: $testBaseDir", "Error", "OK", "Error")
        return
    }
    
    $categories = Get-ChildItem -Path $testBaseDir -Directory
    
    if ($categories.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No test categories found in $testBaseDir", "Error", "OK", "Error")
        return
    }
    
    # Add categories to listbox
    $categoriesListBox.Items.Clear()
    foreach ($category in $categories) {
        $categoriesListBox.Items.Add($category.Name)
    }
    
    # Show categories view
    ShowCategoriesView
}

# Function to select a category
function SelectCategory($category) {
    $global:currentPath = @($category)
    $categoryPath = Join-Path (Join-Path (Get-Location) "tests") $category
    
    # Check if it has subdirectories
    $subcategories = Get-ChildItem -Path $categoryPath -Directory
    
    if ($subcategories.Count -gt 0) {
        DisplaySubcategories $category $subcategories
    } else {
        DisplayTests $category $categoryPath
    }
}

# Function to display subcategories
function DisplaySubcategories($categoryName, $subcategoriesObjects) {
    # Set title
    $subcategoriesTitleLabel.Text = "$categoryName Subcategories"
    
    # Clear subcategories list
    $subcategoriesListBox.Items.Clear()
    
    # Add subcategories to listbox
    foreach ($subcategory in $subcategoriesObjects) {
        $subcategoriesListBox.Items.Add($subcategory.Name)
    }
    
    # Show subcategories view
    HideAllPanels
    $subcategoriesPanel.Visible = $true
}

# Function to select a subcategory
function SelectSubcategory($subcategory) {
    $global:currentPath += $subcategory
    
    # Get subcategory path
    $subcategoryPath = Join-Path (Get-Location) "tests"
    foreach ($part in $global:currentPath) {
        $subcategoryPath = Join-Path $subcategoryPath $part
    }
    
    # Check if it has subdirectories
    $subsubcategories = Get-ChildItem -Path $subcategoryPath -Directory
    
    if ($subsubcategories.Count -gt 0) {
        DisplaySubcategories $subcategory $subsubcategories
    } else {
        DisplayTests $subcategory $subcategoryPath
    }
}

# Function to display tests
function DisplayTests($title, $testsPath) {
    # Set title
    $testsTitleLabel.Text = "$title Tests"
    
    # Clear tests list
    $testsListBox.Items.Clear()
    
    # Get all JSON test files
    $testFiles = Get-ChildItem -Path $testsPath -Filter "*.json"
    
    if ($testFiles.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No JSON test files found in selected path: $testsPath", "No Tests Found", "OK", "Information")
        HandleBackFromTests
        return
    }
    
    # Add tests to listbox
    foreach ($file in $testFiles) {
        try {
            # Read file to get test metadata
            $testContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            
            # Get test name and details
            $testName = if ($testContent.PSObject.Properties.Name -contains "name") { $testContent.name } else { $file.BaseName }
            $questionCount = if ($testContent.PSObject.Properties.Name -contains "questionCount") { 
                $testContent.questionCount 
            } elseif ($testContent.questions) { 
                $testContent.questions.Count 
            } else { 
                "Unknown" 
            }
            $timeLimit = if ($testContent.PSObject.Properties.Name -contains "timeLimit") { "$($testContent.timeLimit) minutes" } else { "No limit" }
            
            $testInfo = "$testName - Questions: $questionCount, Time: $timeLimit"
            $testsListBox.Items.Add($testInfo)
        }
        catch {
            $testsListBox.Items.Add("$($file.BaseName) [Unable to read file details]")
        }
    }
    
    # Show tests view
    HideAllPanels
    $testsPanel.Visible = $true
}

# Function to select a test
function SelectTest($selectedTestName) {
    # Find the file that matches the selected test name
    $testsPath = Join-Path (Get-Location) "tests"
    foreach ($part in $global:currentPath) {
        $testsPath = Join-Path $testsPath $part
    }
    
    $testFiles = Get-ChildItem -Path $testsPath -Filter "*.json"
    $selectedFile = $null
    
    foreach ($file in $testFiles) {
        try {
            $testContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            
            $testName = if ($testContent.PSObject.Properties.Name -contains "name") { $testContent.name } else { $file.BaseName }
            
            if ($testName -eq $selectedTestName) {
                $selectedFile = $file
                $global:currentTestData = $testContent
                break
            }
        }
        catch {
            continue
        }
    }
    
    if ($selectedFile -eq $null) {
        [System.Windows.Forms.MessageBox]::Show("Could not find the selected test file.", "Error", "OK", "Error")
        return
    }
    
    # Display test info
    DisplayTestInfo $selectedFile.BaseName $global:currentTestData
}

# Function to display test info
function DisplayTestInfo($fileName, $testData) {
    # Get test info
    $testName = if ($testData.PSObject.Properties.Name -contains "name") { $testData.name } else { $fileName }
    $questionCount = if ($testData.PSObject.Properties.Name -contains "questionCount") { 
        $testData.questionCount 
    } elseif ($testData.questions) { 
        $testData.questions.Count 
    } else { 
        "Unknown" 
    }
    $timeLimit = if ($testData.PSObject.Properties.Name -contains "timeLimit") { $testData.timeLimit } else { 0 }
    
    # Set title
    $testInfoTitleLabel.Text = $testName
    
    # Create test info
    $testInfoContentLabel.Text = "Test Name: $testName`n`n"
    $testInfoContentLabel.Text += "Questions: $questionCount`n`n"
    
    if ($timeLimit -gt 0) {
        $testInfoContentLabel.Text += "Time Limit: $timeLimit minutes`n`n"
    } else {
        $testInfoContentLabel.Text += "Time Limit: No limit`n`n"
    }
    
    $testInfoContentLabel.Text += "Click 'Start Test' when you're ready to begin.`n`n"
    $testInfoContentLabel.Text += "You can navigate between questions using the Previous and Next buttons.`n"
    $testInfoContentLabel.Text += "You can also skip questions if you're not sure of the answer.`n"
    $testInfoContentLabel.Text += "No feedback will be provided during the test - results will be shown at the end."
    
    # Show test info view
    HideAllPanels
    $testInfoPanel.Visible = $true
}

# Function to start the test
function StartTest {
    # Reset user answers and current question index
    $global:userAnswers = @()
    $global:currentQuestionIndex = 0
    $global:selectedOption = $null
    
    # Set test time limit
    if ($global:currentTestData.PSObject.Properties.Name -contains "questions") {
        $global:testTimeLimit = if ($global:currentTestData.PSObject.Properties.Name -contains "timeLimit") { [double]$global:currentTestData.timeLimit } else { 0 }
    } else {
        $global:testTimeLimit = 0
    }
    
    # Record start time
    $global:testStartTime = Get-Date
    
    # Initialize the timer if time limit is set
    if ($global:testTimeLimit -gt 0) {
        StartTimer $global:testTimeLimit
    } else {
        $timerCountdownLabel.Text = "No time limit"
    }
    
    # Show first question
    ShowQuestion 0
    
    # Show test view
    HideAllPanels
    $testPanel.Visible = $true
}

# Function to start timer
# Function to start timer - with debugging
function StartTimer($minutes) {
    $minutesToAdd = [double]$minutes
    $global:endTime = (Get-Date).AddMinutes($minutesToAdd)
    Write-Host "Timer will expire at $global:endTime"
    
    # Update timer immediately
    UpdateTimer $global:endTime
    
    $global:testTimer = New-Object System.Windows.Forms.Timer
    $global:testTimer.Interval = 1000
    $global:testTimer.Add_Tick({
        UpdateTimer $global:endTime
    })
    $global:testTimer.Start()
}


# Function to update timer
function UpdateTimer($endTime) {
    $now = Get-Date
    $diff = $endTime - $now
    
    if ($diff.TotalSeconds -le 0) {
        # Time's up
        if ($global:testTimer) {
            $global:testTimer.Stop()
            $global:testTimer.Dispose()
            $global:testTimer = $null
        }
        
        $timerCountdownLabel.Text = "TIME EXPIRED!"
        $timerCountdownLabel.ForeColor = [System.Drawing.Color]::Red
        
        # End the test after a short delay
        $script:endTestTimer = New-Object System.Windows.Forms.Timer
        $script:endTestTimer.Interval = 2000
        $script:endTestTimer.Add_Tick({
            $script:endTestTimer.Stop()
            $script:endTestTimer.Dispose()
            EndTest
        })
        $script:endTestTimer.Start()
        
        return
    }
    
    # Calculate minutes and seconds
    $minutes = [math]::Floor($diff.TotalMinutes)
    $seconds = [math]::Floor($diff.TotalSeconds % 60)
    
    # Update timer display
    $timerCountdownLabel.Text = "Time Remaining: " + $minutes + ":" + $seconds.ToString("00")
    
    # Set color warnings
    if ($diff.TotalSeconds -lt 60) {
        $timerCountdownLabel.ForeColor = [System.Drawing.Color]::Red
    } elseif ($diff.TotalSeconds -lt 300) {
        $timerCountdownLabel.ForeColor = [System.Drawing.Color]::DarkOrange
    } else {
        $timerCountdownLabel.ForeColor = [System.Drawing.Color]::Black
    }
}

# Function to show a question
function ShowQuestion($index) {
    # Get questions
    $questions = if ($global:currentTestData.PSObject.Properties.Name -contains "questions") { 
        $global:currentTestData.questions 
    } else { 
        $global:currentTestData 
    }
    
    if ($index -lt 0 -or $index -ge $questions.Count) {
        return
    }
    
    $question = $questions[$index]
    
    # Update current question index
    $global:currentQuestionIndex = $index
    
    # Update question counter
    $timerQuestionLabel.Text = "Question $($index + 1) of $($questions.Count)"
    
    # Set question text
    $questionTextLabel.Text = $question.question
    
    # Clear options panel
    $optionsPanel.Controls.Clear()
    
    # Create radio buttons for options
    for ($i = 0; $i -lt $question.options.Count; $i++) {
        $option = $question.options[$i]
        $yPos = 10 + ($i * 40)
        
        $radioButton = New-Object System.Windows.Forms.RadioButton
        $radioButton.Text = "$($i+1). $option"
        $radioButton.Location = New-Object System.Drawing.Point(10, $yPos)
        $radioButton.Size = New-Object System.Drawing.Size(700, 30)
        $radioButton.Tag = $i  # Store option index in Tag property
        $radioButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        
        # Check if this option is already selected
        if ($global:userAnswers.Count -gt $index -and $global:userAnswers[$index] -eq $i) {
            $radioButton.Checked = $true
            $global:selectedOption = $radioButton
        }
        
        # Create a scriptblock to handle the click event
        $clickHandler = {
            param($sender, $e)
            SelectOption $sender.Tag
        }
        
        # Register the event handler
        $radioButton.Add_Click($clickHandler)
        
        $optionsPanel.Controls.Add($radioButton)
    }
    
    # Update navigation buttons
    $prevQuestionButton.Enabled = $index -gt 0
    
    # Enable next button if an answer is selected for this question
    $nextQuestionButton.Enabled = $global:userAnswers.Count -gt $index -and $global:userAnswers[$index] -ne $null
    
    # If it's the last question, change next button text
    if ($index -eq $questions.Count - 1) {
        $nextQuestionButton.Text = "Finish"
    } else {
        $nextQuestionButton.Text = "Next"
    }
}

# Function to select an option
function SelectOption($optionIndex) {
    # Store user answer
    if ($global:userAnswers.Count -le $global:currentQuestionIndex) {
        # Add new answer
        $global:userAnswers += @($optionIndex)
    } else {
        # Update existing answer
        $global:userAnswers[$global:currentQuestionIndex] = $optionIndex
    }
    
    # Enable next button
    $nextQuestionButton.Enabled = $true
    
    # Get questions
    $questions = if ($global:currentTestData.PSObject.Properties.Name -contains "questions") { 
        $global:currentTestData.questions 
    } else { 
        $global:currentTestData 
    }
    
    # Automatically go to next question if not the last one
    if ($global:currentQuestionIndex -lt $questions.Count - 1) {
        # Short delay before going to next question
        $script:autoNextTimer = New-Object System.Windows.Forms.Timer
        $script:autoNextTimer.Interval = 300
        $script:autoNextTimer.Add_Tick({
            $script:autoNextTimer.Stop()
            $script:autoNextTimer.Dispose()
            ShowNextQuestion
        })
        $script:autoNextTimer.Start()
    }
}

# Function to show previous question
function ShowPreviousQuestion {
    if ($global:currentQuestionIndex -gt 0) {
        ShowQuestion ($global:currentQuestionIndex - 1)
    }
}

# Function to show next question
function ShowNextQuestion {
    # Get questions
    $questions = if ($global:currentTestData.PSObject.Properties.Name -contains "questions") { 
        $global:currentTestData.questions 
    } else { 
        $global:currentTestData 
    }
    
    if ($global:currentQuestionIndex -lt $questions.Count - 1) {
        ShowQuestion ($global:currentQuestionIndex + 1)
    } else {
        # This is the last question, end the test
        EndTest
    }
}

# Function to skip question
function SkipQuestion {
    # Mark question as skipped (-1)
    if ($global:userAnswers.Count -le $global:currentQuestionIndex) {
        # Add new answer
        $global:userAnswers += @(-1)
    } else {
        # Update existing answer
        $global:userAnswers[$global:currentQuestionIndex] = -1
    }
    
    # Go to next question or end test if last question
    $questions = if ($global:currentTestData.PSObject.Properties.Name -contains "questions") { 
        $global:currentTestData.questions 
    } else { 
        $global:currentTestData 
    }
    
    if ($global:currentQuestionIndex -lt $questions.Count - 1) {
        ShowQuestion ($global:currentQuestionIndex + 1)
    } else {
        EndTest
    }
}

# Function to confirm quit test
function ConfirmQuitTest {
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Are you sure you want to quit the test? Your progress will be lost.",
        "Quit Test",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        # Stop timer
        if ($global:testTimer) {
            $global:testTimer.Stop()
            $global:testTimer.Dispose()
            $global:testTimer = $null
        }
        
        # Return to main menu
        ShowCategoriesView
    }
}

# Function to end the test
function EndTest {
    # Stop timer
    if ($global:testTimer) {
        $global:testTimer.Stop()
        $global:testTimer.Dispose()
        $global:testTimer = $null
    }
    
    # Record end time
    $testEndTime = Get-Date
    
    # Calculate score
    $questions = if ($global:currentTestData.PSObject.Properties.Name -contains "questions") { 
        $global:currentTestData.questions 
    } else { 
        $global:currentTestData 
    }
    
    $score = 0
    
    for ($i = 0; $i -lt $global:userAnswers.Count; $i++) {
        if ($global:userAnswers[$i] -eq $questions[$i].answer) {
            $score++
        }
    }
    
    $totalQuestions = $questions.Count
    $percentScore = [math]::Round(($score / $totalQuestions) * 100, 2)
    
    # Calculate time taken
    $timeTaken = $testEndTime - $global:testStartTime
    $minutesTaken = [math]::Floor($timeTaken.TotalMinutes)
    $secondsTaken = [math]::Floor($timeTaken.TotalSeconds % 60)
    
    # Update results view
    $scorePercentLabel.Text = "$percentScore%"
    $scoreDetailLabel.Text = "$score out of $totalQuestions correct"
    $timeDetailLabel.Text = "Time: " + $minutesTaken + ":" + $secondsTaken.ToString("00")
    
    # Set feedback and color
    if ($percentScore -ge 90) {
        $scoreFeedbackLabel.Text = "Excellent work!"
        $scoreFeedbackLabel.ForeColor = [System.Drawing.Color]::Green
    } elseif ($percentScore -ge 70) {
        $scoreFeedbackLabel.Text = "Good job!"
        $scoreFeedbackLabel.ForeColor = [System.Drawing.Color]::Green
    } elseif ($percentScore -ge 50) {
        $scoreFeedbackLabel.Text = "You passed, but there's room for improvement."
        $scoreFeedbackLabel.ForeColor = [System.Drawing.Color]::DarkOrange
    } else {
        $scoreFeedbackLabel.Text = "You might want to study more and try again."
        $scoreFeedbackLabel.ForeColor = [System.Drawing.Color]::Red
    }
    
    # Show results view
    HideAllPanels
    $resultsPanel.Visible = $true
}

# Function to go back from test info
function HandleBackFromTestInfo {
    # Clear current test data
    $global:currentTestData = $null
    
    # Show tests view
    HideAllPanels
    $testsPanel.Visible = $true
}

# Function to go back from tests
function HandleBackFromTests {
    # Remove the last part from the path
    $global:currentPath = $global:currentPath[0..($global:currentPath.Length-2)]
    
    if ($global:currentPath.Length -eq 0) {
        # Show categories view
        ShowCategoriesView
    } else {
        # Get content for the current path
        $path = Join-Path (Get-Location) "tests"
        foreach ($part in $global:currentPath[0..($global:currentPath.Length-2)]) {
            $path = Join-Path $path $part
        }
        
        $subcategories = Get-ChildItem -Path $path -Directory | Where-Object { $_.Name -eq $global:currentPath[-1] }
        
        if ($subcategories) {
            # Get subdirectories of the current path
            $path = Join-Path $path $global:currentPath[-1]
            $subcategories = Get-ChildItem -Path $path -Directory
            
            # Show subcategories view
            DisplaySubcategories $global:currentPath[-1] $subcategories
        } else {
            # Show categories view as fallback
            ShowCategoriesView
        }
    }
}

# Function to show categories view
function ShowCategoriesView {
    # Reset path
    $global:currentPath = @()
    
    # Clear current test data
    $global:currentTestData = $null
    
    # Hide all panels
    HideAllPanels
    $categoriesPanel.Visible = $true
}

# Function to hide all panels
function HideAllPanels {
    $categoriesPanel.Visible = $false
    $subcategoriesPanel.Visible = $false
    $testsPanel.Visible = $false
    $testInfoPanel.Visible = $false
    $testPanel.Visible = $false
    $resultsPanel.Visible = $false
}

# Load test categories when the application starts
LoadTestCategories

# Show the form
$mainForm.ShowDialog()