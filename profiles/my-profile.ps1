# Git helper functions
function init { git init }
function status { git status }
function add { 
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть шлях до файлу(ів)")]
        [string]$File
    )
    git add $File 
}
function branch { git branch }
function diff { git diff }
function pull { git pull }
function del-branch { 
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть назву гілки")]
        [string]$Branch
    )
    git branch -D $Branch 
}
function del-remote { 
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть назву гілки")]
        [string]$Branch,
        [string]$Remote = "origin"
    )
    git push $Remote --delete $Branch 
}
function clean { git clean -fd }
function reset { git reset }
function reset-hard { git reset --hard HEAD}
function unindex { 
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть шлях до файлу(ів)")]
        [string]$Name
    )
    git rm -rf --cached $Name 
}
function clear-index { git rm --cached -r . -f }
function current {
    param (
        [switch]$Verbose
    )

    $currentBranch = git rev-parse --abbrev-ref HEAD

    if ($Verbose) {
        Write-Host "Getting current branch name..."
        Write-Host "Current branch is: " -NoNewLine
        Write-Host $currentBranch -ForegroundColor Yellow
    }

    return $currentBranch
}

function fetch { git fetch --all }
function fetch-remote { 
    param (
        [string]$Remote = "origin"
    )

    git fetch $Remote
}
function fetch-prune { 
    param (
        [string]$Remote = "origin"
    )

    git fetch $Remote --prune
}
function fetch-prune-tags { git fetch --all --prune-tags }
function fetch-prune-all { git fetch --all --prune --prune-tags }
function fetch-branch {
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть назву гілки")]
        [string]$Branch,
        [string]$Remote = "origin"
    )

    Write-Host " "

    if ((check $Remote) -ne 0) {
        Write-Host "Remote '$Remote' is not reachable." -ForegroundColor Red
        return
    }

    Write-Host "Fetching branch '$Branch' from remote '$Remote'..." -ForegroundColor Cyan
    git fetch $Remote $Branch
    Write-Host "Fetch completed." -ForegroundColor Green
    Write-Host " "
    return
}

function list-local {
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть назву гілки, або її частину")]
        [string]$Branch
    )

    Write-Host " "
    Write-Host "Searching for similar branches for '$Branch'... " -NoNewLine
    $matchingBranches = @(git branch --list "*$Branch*" | ForEach-Object { $_.Trim().TrimStart('* ') } | Where-Object { $_ -ne '' })
    
    if ($matchingBranches.Count -eq 1) {
        Write-Host "Found one matching branch!" -ForegroundColor Magenta
        Write-Host " "
        Write-Host "$($matchingBranches[0])" -ForegroundColor Green
        Write-Host " "
        return
    } elseif ($matchingBranches.Count -gt 1) {
        Write-Host "Found multiple branches matching!" -ForegroundColor Yellow
        Write-Host " "
        $matchingBranches | ForEach-Object {
            Write-Host "$_" -ForegroundColor Cyan
        }
        Write-Host " "
        return
    }

    Write-Host " "
    Write-Host "No matching branches found." -ForegroundColor Red
    Write-Host " "
    return
}

function list-remote {
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть назву гілки, або її частину")]
        [string]$Branch,
        [string]$Remote = "origin"
    )

    Write-Host " "

    if ((check $Remote) -ne 0) {
        Write-Host "Remote '$Remote' is not reachable." -ForegroundColor Red
        return
    }

    Write-Host "Searching for similar remote branches for '$Branch'... " -NoNewLine
    $matchingBranches = @(git ls-remote --heads $Remote "*$Branch*" | ForEach-Object { ($_ -split "`t")[1].Replace("refs/heads/", "").Trim() } | Where-Object { $_ -ne '' })
    
    if ($matchingBranches.Count -eq 1) {
        Write-Host "Found one matching remote branch!" -ForegroundColor Magenta
        Write-Host " "
        Write-Host "$($matchingBranches[0])" -ForegroundColor Green
        Write-Host " "
        return
    } elseif ($matchingBranches.Count -gt 1) {
        Write-Host "Found multiple remote branches matching!" -ForegroundColor Yellow
        Write-Host " "
        $matchingBranches | ForEach-Object {
            Write-Host "$_" -ForegroundColor Cyan
        }
        Write-Host " "
        return
    }

    Write-Host " "
    Write-Host "No matching remote branches found." -ForegroundColor Red
    Write-Host " "
    return
}

# Check function to verify if the remote repository is reachable
function check {
    param (
        [string]$Remote = "origin"
    )

    $remoteUrl = git config --get "remote.$Remote.url"
    if (-not $remoteUrl -or $remoteUrl.Trim() -eq '') {
        Write-Host " "
        Write-Host "Remote url is not set for '$Remote'!" -ForegroundColor Red
        Write-Host " "
        return -1
    }

    Write-Host " "
    Write-Host "Checking remote " -NoNewLine
    Write-Host "$remoteUrl..." -ForegroundColor Cyan

    git ls-remote --exit-code -h "$remoteUrl" | Out-Null
    $code = $LASTEXITCODE

    if ($code -eq 0) {
        Write-Host "✅ Success: The remote server is online and reachable." -ForegroundColor Green
    } else {
        Write-Host "❌ Error: Could not reach the remote server." -ForegroundColor Red
    }

    Write-Host " "
    return $code
}

function has-changes {
    $hasChanges = git status --porcelain
    return ($hasChanges -and $hasChanges.Trim())
}

# Enhanced checkout function with branch existence check and suggestions
function checkout { 
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть назву гілки")]
        [string]$Branch,
        [string]$Remote = "origin"
    )

    if (has-changes) {
        Write-Host "You have uncommitted changes in your working directory." -ForegroundColor Yellow
        Write-Host "Please commit or stash your changes before switching branches." -ForegroundColor Yellow
        Write-Host " "
        status
        return
    }

    Write-Host " "
    Write-Host "Checking out branch '$Branch'..." -ForegroundColor Cyan
    $localBranchExists = git branch --list -- $Branch

    if ($localBranchExists -and $localBranchExists.Trim() -ne '') {
        git checkout $Branch
    } else {
        $remoteBranchExists = git branch -r --list "$Remote/$Branch"

        if ($remoteBranchExists -and $remoteBranchExists.Trim() -ne '') {
            Write-Host "Local branch '$Branch' not found. Creating tracking branch from '$Remote/$Branch'..." -ForegroundColor Magenta
            git checkout -b $Branch --track "$Remote/$Branch"
        } else {
            Write-Host "Branch '$Branch' does not exist locally or on '$Remote'. Creating new local branch..." -ForegroundColor Magenta
            git checkout -b $Branch
        }
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to switch to branch '$Branch'." -ForegroundColor Red
        Write-Host " "
        return
    }

    Write-Host "Switched to branch '$Branch'." -ForegroundColor Green
    Write-Host " "
    return
}

# Update function to pull latest changes from a specified branch and merge into current branch
# If no branch is specified, it pulls latest changes for the current branch
function update {
    param (
        [string]$From = ''
    )
    
    if ((check) -ne 0) {
        Write-Host "Remote is not reachable. Update aborted." -ForegroundColor Red
        return
    }

    if (has-changes) {
        Write-Host "You have uncommitted changes in your working directory." -ForegroundColor Yellow
        Write-Host "Please commit or stash your changes before pulling updates." -ForegroundColor Yellow
        Write-Host " "
        status
        return
    }

    if (-not $From -or $From.Trim() -eq '') {
        Write-Host "Pulling latest changes for current branch" -ForegroundColor Cyan
        pull
        return
    }

    $currentBranch = current
    $branchExists = git branch --list $From
    
    if ($branchExists) {
        Write-Host "Switching to branch '$From'..." -ForegroundColor Cyan
        git checkout $From
        
        Write-Host "Pulling latest changes from '$From'..." -ForegroundColor Cyan
        git pull origin $From
        
        Write-Host "Switching back to '$currentBranch'..." -ForegroundColor Cyan
        git checkout $currentBranch
        
        Write-Host "Merging '$From' into '$currentBranch'..." -ForegroundColor Cyan
        git merge $From
        
        Write-Host "Done!" -ForegroundColor Green
        return
    } else {
        Write-Host "Branch '$From' does not exist locally." -ForegroundColor Red
        Write-Host "Update aborted." -ForegroundColor Red
        return
    }
}

function upstream {
	param (
      [Parameter(Mandatory, HelpMessage = "Введіть назву гілки")]
	  [string]$Branch,
	  [string]$Origin = 'origin'
	)
	
    if ((check $Origin) -ne 0) {
        Write-Host "Cannot set upstream because remote '$Origin' is not reachable." -ForegroundColor Red
        return
    }

    Write-Host " "
    Write-Host "Setting upstream for branch '$Branch' to remote '$Origin'..." -ForegroundColor Green
	git push --set-upstream $Origin $Branch
    Write-Host " "
    return
}

function clone { 
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть URL репозиторію")]
        [string]$Repository, 
        [Parameter(Mandatory, HelpMessage = "Введіть цільову теку (для поточної теки використайте '.')")]
        [string]$Target, 
        [int]$Depth = 0
    )

    if ($Depth -gt 0) {
        git clone --depth $Depth $Repository $Target
    } else {
        git clone $Repository $Target
    }
}

function clone-one {
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть URL репозиторію")]
        [string]$Repository, 
        [Parameter(Mandatory, HelpMessage = "Введіть цільову теку (для поточної теки використайте '.')")]
        [string]$Target
    )

    clone -Repository $Repository -Target $Target -Depth 1
}

function rename {
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть нову назву гілки")]
        [string]$NewName,
        [string]$OldName
    )

    $currentBranch = current

    git branch -m $OldName $NewName
}

function restore-from {
    param (
        [string]$Name,
        [string]$Source = "master"
    )

    if (-not $Name -or $Name.Trim() -eq '') {
        Write-Host "File name cannot be empty." -ForegroundColor Red
        return
    }

    Write-Host "Restoring file '$Name' from '$Source'..." -ForegroundColor Cyan
    git restore --source=$Source $Name
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to restore file '$Name' from '$Source'." -ForegroundColor Red
        return
    }
    Write-Host "File '$Name' restored successfully." -ForegroundColor Green
}

function restore {
    param (
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Names
    )
    
    if ($Names.Count -eq 0) {
        git restore .
    } else {
        git restore $Names
    }
}

function commit {
    param (
      [string]$Message = "Update files"
    )
    git add .
    git commit -m $Message
}

function update-commit {
    git commit --amend
}

function push {
    param (
        [string]$Message,
        [string]$Remote = "origin",
        [switch]$Simple,
        [switch]$Force
    )

    Write-Host " "

    $changes = git diff --shortstat

    Write-Host "Pushing current changes..."

    if ((check $Remote) -ne 0) {
        Write-Host " "
        Write-Host "Cannot push, because remote '$Remote' is not reachable." -ForegroundColor Red
        Write-Host " "
        return
    }

    # Перевірка на вхідні зміни (чи потрібно pull)
    Write-Host "Checking incoming changes for '$Remote/$branchName'..." -ForegroundColor Cyan
    $remoteBranchExists = (git ls-remote --heads $Remote $branchName)

    if ($remoteBranchExists -and $remoteBranchExists.Trim()) {
        git fetch $Remote $branchName --quiet 2>$null

        $counts = git rev-list --left-right --count "HEAD...$Remote/$branchName" 2>$null
        if ($LASTEXITCODE -eq 0 -and $counts) {
            $parts = $counts.Trim() -split '\s+'
            $ahead = [int]$parts[0]
            $behind = [int]$parts[1]

            if ($behind -gt 0 -and -not $Force) {
                Write-Host "⚠️  Your branch is behind '$Remote/$branchName' by $behind commit(s)." -ForegroundColor Yellow
                Write-Host "Run pull first, then push." -ForegroundColor Yellow
                Write-Host "Use -Force to skip this check (not recommended)." -ForegroundColor Yellow
                Write-Host " "
                return
            }
        }
    }

    if ($Simple) {
        Write-Host "Using only push command..." -ForegroundColor Yellow
        git push
        Write-Host " "    
        Write-Host "Push operation completed." -ForegroundColor Green
        Write-Host " "   
        return
    }

    Write-Host "Getting current branch name..." 
    $branchName = current

    Write-Host "Current branch is: " -NoNewLine
    Write-Host $branchName -ForegroundColor Yellow

    Write-Host "Preparing to push changes to remote '$Remote'..."
    Write-Host "Commit message: " -NoNewLine
    Write-Host $Message -ForegroundColor Magenta
    Write-Host "Changes:" -NoNewLine
    Write-Host ($changes ? $changes : "No changes") -ForegroundColor Magenta

    Write-Host "Adding changes and committing..."
    $null = git add .
    $null = git commit -m $Message

    Write-Host "Checking if remote branch '$branchName' exists on '$Remote'..."
    $branchExists = (git ls-remote --heads $Remote $branchName)

    if ($branchExists -and $branchExists.Trim()) {
        Write-Host "Remote branch $branchName exists. Pushing changes..."
        git push 2>&1 | Out-Null
    } else {
        Write-Host "Remote branch $branchName doesn't exists. Creating new remote branch and pushing changes..."
        $null = git push -u $Remote $branchName
    }

    Write-Host " "    
    Write-Host "Push operation completed." -ForegroundColor Green
    Write-Host " "   
    return
}

function log { 
    param (
        [int]$Deep = 1
    )
    if ($Deep -gt 0) {
        $Deep = $Deep * -1
    }
    git log $Deep 
}

function exists {
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть назву гілки")]
        [string]$Name,
        [string]$Remote = ""
    )

    $branchExists = 'false'

    if ($Remote -and $Remote.Trim()) {
        Write-Host "Check remote branch for existing..." -NoNewLine
        $branchExists = (git ls-remote --heads $Remote $Name)
    } else {
        Write-Host "Check local branch for existing..." -NoNewLine
        $branchExists = (git branch --list | Select-String -Pattern $Name -Quiet) 
    }

    return ($branchExists -ne $null)
}

function create {
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть тип гілки")]
        [string]$Type,
        [Parameter(Mandatory, HelpMessage = "Введіть назву гілки")]
        [string]$Name,
        [string]$From = "master",
        [switch]$Force
    )

    Write-Host " "

    if (has-changes) {
        Write-Host "You have uncommitted changes in your working directory." -ForegroundColor Yellow
        Write-Host "Please commit or stash your changes before creating a new branch." -ForegroundColor Yellow
        Write-Host " "
        status
        return
    }

    $new_name = $Type.trim() -eq '' ? $Name : "$Type/$Name"
    Write-Host "Creating new branch '$new_name' from '$From'..." -ForegroundColor Cyan
    if (exists -Name $new_name) {
        Write-Host "Branch $new_name already exists." -ForegroundColor Red
        Write-Host " "
        return
    }

    Write-Host "Checking out to source branch '$From'..." -ForegroundColor Cyan
    checkout $From

    # if ($LASTEXITCODE -eq 3) {
    #     Write-Host "Cannot create branch because multiply source branches found." -ForegroundColor Red
    #     Write-Host " "
    #     return
    # }

    if ($LASTEXITCODE -ne 0 -and -not $Force) {
        Write-Host "Cannot create branch because source branch '$From' does not exist." -ForegroundColor Red
        Write-Host " "
        return
    }

    Write-Host "Creating new branch $new_name..." -ForegroundColor Cyan
    $null = git checkout -b $new_name
    Write-Host "Branch $new_name created successfully." -ForegroundColor Green

    Write-Host " "
    return
}

function feature { 
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть назву гілки")]
        [string]$Name,
        [string]$From = "master"
    )

    create -Type "feature" -Name $Name -From $From
}

function review { 
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть назву гілки")]
        [string]$Name,
        [string]$From = "master"
    )

    create -Type "review" -Name $Name -From $From
}

function hotfix { 
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть назву гілки")]
        [string]$Name,
        [string]$From = "master"
    )

    create -Type "hotfix" -Name $Name -From $From
}

function release { 
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть назву гілки")]
        [string]$Name,
        [string]$From = "master"
    )

    create -Type "release" -Name $Name -From $From
}

function merge {
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть назву гілки яку потрібно злити в поточну")]
        [string]$Branch,
        [switch]$D
    )

    if (has-changes) {
        Write-Host "You have uncommitted changes in your working directory." -ForegroundColor Yellow
        Write-Host "Please commit or stash your changes before merging branches." -ForegroundColor Yellow
        Write-Host " "
        status
        return
    }

    if ((-not $Branch -or $Branch.Trim() -eq '')) {
        Write-Host "Branch name cannot be empty." -ForegroundColor Red
        Write-Host "Use " -NoNewLine
        Write-Host "merge <branch>" -ForegroundColor Cyan -NoNewLine
        Write-Host " to merge branches."
        Write-Host " "
        return
    }

    if ((check) -eq 0) {
        Write-Host "Pulling latest changes for current branch..." -ForegroundColor Cyan
        $null = git pull origin $(current)
    }

    Write-Host "Merging $Branch into current." -ForegroundColor Cyan
    if ($D) {
        git merge $Branch --verbose
    } else {
        git merge $Branch
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Merge failed." -ForegroundColor Red
        Write-Host " "
        return
    }

    Write-Host "Merge completed." -ForegroundColor Green
    Write-Host " "
    return
}

# Shell functions from linux

Set-Alias -Name which -Value search

Remove-Alias -Name pwd -Force -ErrorAction SilentlyContinue
Remove-Alias -Name cat -Force -ErrorAction SilentlyContinue
Remove-Alias -Name ls -Force -ErrorAction SilentlyContinue

function search {
    param (
        [string]$Path = ".",
        [Parameter(Mandatory, HelpMessage = "Введіть назву файлу або її частину")]
        [string]$File,
        [int]$Depth = 0  # 0 = без обмежень
    )
    
    if (-not (Test-Path $Path)) {
        Write-Warning "Шлях '$Path' не існує"
        return
    }
    
    $params = @{
        Path = $Path
        Recurse = $true
        Force = $true
        File = $true
        Filter = "*$File*"
        ErrorAction = 'SilentlyContinue'
    }
    
    # Додаємо обмеження глибини якщо вказано
    if ($Depth -gt 0) {
        $params.Depth = $Depth
    }
    
    Get-ChildItem @params | Select-Object -ExpandProperty FullName
}

function ls { 
    param (
        [string]$Path = ".",
        [string]$Pattern = "*",
        [switch]$C
    )

    Write-Host " "
    Write-Host "Listing items..."
    Write-Host " "

    # Check if Terminal-Icons is available
    if (Get-Module -Name Terminal-Icons) {
        # Use Get-ChildItem with Format-TerminalIcons for icon support
        Get-ChildItem -Path $Path -Filter "*$Pattern*" -ErrorAction SilentlyContinue | 
        Format-TerminalIcons | 
        ForEach-Object {
            if ($C) {
                Write-Host $_ 
            } else {
                Write-Host "$_ " -NoNewLine
            }
        }
    } else {
        # Fallback to your original implementation
        Get-ChildItem -Name -Path $Path -Filter "*$Pattern*" -ErrorAction SilentlyContinue | 
        ForEach-Object {
            $item = Get-Item -Path (Join-Path -Path $Path -ChildPath $_) -ErrorAction SilentlyContinue
            if ($item) {
                $isDir = $item.PSIsContainer
                $color = if ($isDir) { "White" } else { "Cyan" }
                Write-Host "$_ " -ForegroundColor $color -NoNewLine:(-not $C)
            }
        }
    }

    if (-not $C) {
        Write-Host ""
    }
    Write-Host " "
}

function la { 
    param (
        [string]$Path = ".", 
        [string]$Pattern = "*"
    )
    Get-ChildItem -Path $Path -Filter "*$Pattern*" -ErrorAction SilentlyContinue
}

function lf { 
    param (
        [string]$Path = ".", 
        [string]$Pattern = "*"
    )
    Get-ChildItem -Path $Path -Filter "*$Pattern*" -Force -ErrorAction SilentlyContinue
}

function lr { 
    param (
        [string]$Path = ".", 
        [string]$Pattern = "*"
    )
    Get-ChildItem -Path $Path -Filter "*$Pattern*" -Force -Recurse -ErrorAction SilentlyContinue
}

function tail {
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть шлях до файлу")]
        [string]$Path,
        [int]$Lines = 10,
        [switch]$F
    )

    Get-Content -Path $Path -Tail $Lines -Wait:$F
}

function pwd { Get-Location }
function cat { 
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть шлях до файлу")]
        [string]$file
    )
    Get-Content $file 
}
function touch { 
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть шлях до файлу")]
        [string]$Path
    )
    New-Item -Path $Path -ItemType File 
}
function clear { cls }

function grep {
    param(
        [Parameter(Mandatory, Position=0, HelpMessage = "Введіть строку для пошуку")]
        [string]$Search,
        
        [Parameter(Position=1)]
        [string]$Where,
        
        [Parameter(ValueFromPipeline = $true)]
        [object]$InputObject,
        
        [switch]$IgnoreCase,
        [switch]$CaseSensitive,
        [switch]$Regex,
        [switch]$Invert,
        [switch]$Count,
        [switch]$LineNumber,
        [int]$Context = 0,
        [switch]$Quiet,
        [switch]$Recurse,
        [string[]]$Include,
        [string[]]$Exclude
    )

    begin {
        # Ініціалізуємо масив для збору даних з pipeline
        $pipelineInput = @()
    }

    process {
        # Збираємо всі об'єкти з pipeline
        if ($InputObject -ne $null) {
            $pipelineInput += $InputObject
        }
    }

    end {
        # Визначаємо джерело контенту
        if ($Where) {
            # Перевіряємо чи це файл або директорія
            if (Test-Path $Where -PathType Container) {
                # Пошук у директорії
                $searchParams = @{
                    Path = $Where
                    Pattern = $Search
                    SimpleMatch = !$Regex
                }
                
                if ($Recurse) { $searchParams.Recurse = $true }
                if ($Include) { $searchParams.Include = $Include }
                if ($Exclude) { $searchParams.Exclude = $Exclude }
                if ($CaseSensitive) { $searchParams.CaseSensitive = $true }
                elseif ($IgnoreCase) { $searchParams.CaseSensitive = $false }
                if ($Context -gt 0) { $searchParams.Context = $Context, $Context }
                if ($Invert) { $searchParams.NotMatch = $true }
                
                $results = Select-String @searchParams
            }
            elseif (Test-Path $Where -PathType Leaf) {
                # Пошук у файлі
                $searchParams = @{
                    Path = $Where
                    Pattern = $Search
                    SimpleMatch = !$Regex
                }
                
                if ($CaseSensitive) { $searchParams.CaseSensitive = $true }
                elseif ($IgnoreCase) { $searchParams.CaseSensitive = $false }
                if ($Context -gt 0) { $searchParams.Context = $Context, $Context }
                if ($Invert) { $searchParams.NotMatch = $true }
                
                $results = Select-String @searchParams
            }
            else {
                Write-Error "Файл або директорія '$Where' не знайдена"
                return
            }
        }
        else {
            # Працюємо з pipeline input
            if ($pipelineInput.Count -eq 0) {
                Write-Warning "Немає вхідних даних для пошуку"
                return
            }
            
            $searchParams = @{
                Pattern = $Search
                SimpleMatch = !$Regex
            }
            
            if ($CaseSensitive) { $searchParams.CaseSensitive = $true }
            elseif ($IgnoreCase) { $searchParams.CaseSensitive = $false }
            if ($Context -gt 0) { $searchParams.Context = $Context, $Context }
            if ($Invert) { $searchParams.NotMatch = $true }
            
            # Конвертуємо input в рядки якщо потрібно
            $stringInput = $pipelineInput | ForEach-Object {
                if ($_ -is [string]) {
                    $_
                } else {
                    $_.ToString()
                }
            }
            
            $results = $stringInput | Select-String @searchParams
        }

        # Обробка результатів
        if ($Count) {
            return ($results | Measure-Object).Count
        }
        
        if ($Quiet) {
            return ($results.Count -gt 0)
        }
        
        if ($LineNumber -and $results) {
            $results | ForEach-Object {
                if ($_.Filename) {
                    Write-Host "$($_.Filename):$($_.LineNumber):" -NoNewline -ForegroundColor Yellow
                } else {
                    Write-Host "$($_.LineNumber):" -NoNewline -ForegroundColor Yellow
                }
                Write-Host " $($_.Line)"
            }
        } else {
            $results
        }
    }
}

# Disk usage
function du {
    param(
        [string]$Directory,
        [switch]$K,
        [switch]$M
    ) 

    $dir = $Directory ? $Directory : (Get-Location).Path

    Write-Host ""
    Write-Host "Calculating disk usage for directory: $dir..." -ForegroundColor Cyan

    # Визначаємо одиниці вимірювання
    $unit = if ($K) { 
        "KB" 
    } elseif ($M) { 
        "MB" 
    } else { 
        "B" 
    }

    $divisor = switch ($unit) {
        "KB" { 1KB }
        "MB" { 1MB }
        default { 1 }
    }

    # Оптимізована версія - обчислюємо розмір за один прохід
    $results = Get-ChildItem $dir -ErrorAction SilentlyContinue | ForEach-Object -Parallel {
        $folder = $_
        $using_divisor = $using:divisor
        $using_unit = $using:unit
        
        try {
            $size = (Get-ChildItem -Path $folder.FullName -Recurse -File -ErrorAction SilentlyContinue | 
                    Measure-Object -Property Length -Sum).Sum
            
            $formattedSize = if ($using_unit -eq "B") {
                "{0}" -f $size
            } else {
                "{0:N1}" -f ($size / $using_divisor)
            }
            
            [PSCustomObject]@{
                Name = $folder.Name
                "Size ($using_unit)" = $formattedSize
                SizeBytes = $size
            }
        }
        catch {
            [PSCustomObject]@{
                Name = $folder.Name
                "Size ($using_unit)" = "Error"
                SizeBytes = 0
            }
        }
    } -ThrottleLimit 8

    # Сортуємо по розміру (найбільші спочатку) та виводимо
    $results | Sort-Object SizeBytes -Descending | 
    Format-Table Name, @{Label="Size ($unit)"; Expression={$_."Size ($unit)"}; Align="Right"} -AutoSize

    Write-Host ""
}

# Disk free space
function df {
    param(
        [string]$Path,
        [switch]$H,
        [switch]$K,
        [switch]$M,
        [switch]$T
    )

    $drives = if ($Path) {
        $item = Get-Item $Path -ErrorAction SilentlyContinue
        if ($item) {
            $driveLetter = Split-Path -Path $item.FullName -Qualifier
            Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -eq $driveLetter + "\" -and $_.Name.Length -eq 1 }
        } else {
            Write-Host "Path not found: $Path" -ForegroundColor Red
            return
        }
    } else {
        Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null -and $_.Name.Length -eq 1 }
    }

    $results = $drives | ForEach-Object {
        $drive = $_
        $used = $drive.Used
        $free = $drive.Free
        $total = $used + $free
        $percentUsed = if ($total -gt 0) { [math]::Round(($used / $total) * 100, 1) } else { 0 }

        if ($H) {
            $usedFormatted = Format-Size $used
            $freeFormatted = Format-Size $free
            $totalFormatted = Format-Size $total
        } elseif ($M) {
            $usedFormatted = "{0:F1} MB" -f ($used / 1MB)
            $freeFormatted = "{0:F1} MB" -f ($free / 1MB)
            $totalFormatted = "{0:F1} MB" -f ($total / 1MB)
        } elseif ($K) {
            $usedFormatted = "{0:F0} KB" -f ($used / 1KB)
            $freeFormatted = "{0:F0} KB" -f ($free / 1KB)
            $totalFormatted = "{0:F0} KB" -f ($total / 1KB)
        } else {
            $usedFormatted = "{0} B" -f $used
            $freeFormatted = "{0} B" -f $free
            $totalFormatted = "{0} B" -f $total
        }

        $obj = [PSCustomObject]@{
            Filesystem = $drive.Root
            Size = $totalFormatted
            Used = $usedFormatted
            Available = $freeFormatted
            'Use%' = "$percentUsed%"
        }

        if ($T) {
            $volumeInfo = Get-Volume -DriveLetter $drive.Name -ErrorAction SilentlyContinue
            $fileSystem = if ($volumeInfo) { $volumeInfo.FileSystemType } else { "Unknown" }
            $obj | Add-Member -NotePropertyName "Type" -NotePropertyValue $fileSystem
        }

        $obj
    }

    $results | Format-Table -AutoSize
}

function rn {
	param (
        [Parameter(Mandatory, HelpMessage = "Введіть шлях до файлу/теки")]
		[string]$Path,
        [Parameter(Mandatory, HelpMessage = "Введіть нове ім'я файлу/теки")]
		[string]$NewName
	)
	
	Rename-Item -Path $Path -NewName $NewName
}

# Usefulness functions
function Format-Size {
    param([long]$Bytes)
    
    if ($Bytes -ge 1TB) {
        return "{0:F1} TB" -f ($Bytes / 1TB)
    } elseif ($Bytes -ge 1GB) {
        return "{0:F1} GB" -f ($Bytes / 1GB)
    } elseif ($Bytes -ge 1MB) {
        return "{0:F1} MB" -f ($Bytes / 1MB)
    } elseif ($Bytes -ge 1KB) {
        return "{0:F1} KB" -f ($Bytes / 1KB)
    } else {
        return "{0} B" -f $Bytes
    }
}

function vscode-extensions {
    param (
        [string]$File = "vscode-ext",
        [switch]$Install,
        [switch]$Linux
    )

    $ext = if ($Install) { 
        if ($Linux) { 
            ".sh" 
            } 
        else {
            ".ps1" 
        }
    } else { ".txt" }
    $outputFile = "$File$ext"
    
    Write-Host " "
    Write-Host "Extracting installed VSCode extensions to '$outputFile'..." -NoNewLine
    if ($Install) {
        code --list-extensions | % { "code --install-extension $_" } | Set-Content $outputFile -Encoding UTF8
    } else {
        code --list-extensions | Out-File -FilePath $outputFile -Encoding UTF8
    }
    Write-Host "Done." -ForegroundColor Green
    Write-Host " "
}

function errors {
    param (
        [int]$Count = 5
    )
    $Error | Select-Object -First $Count
}

function last-error {
    $Error[0] | Format-List * -Force
}

function markdown {
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть шлях до markdown файлу")]
        [string]$Path
    )
    Show-Markdown -Path $Path
}

#Set-Alias -Name edit -Value notepad
#Remove-Alias -Name edit -Force -ErrorAction SilentlyContinue

function notepad {
    param (
        [Parameter(Mandatory, HelpMessage = "Введіть шлях до файлу")]
        [string]$File
    )
    & "C:\Program Files\Notepad++\notepad++.exe" $File
} 

# Custom Prompt
# Set to "YES" to show time in prompt, "NO" to hide
$Env:SHOW_PROMPT_TIME = "NO"

function prompt {
    $uptime = Get-Uptime -ErrorAction SilentlyContinue
    $username = $env:USERNAME + ":"
    $currentBranch = current
    $folder = Split-Path -Path (Get-Location) -Leaf
    $nodeVersion = if (Get-Command node -ErrorAction SilentlyContinue) { 
        (node -v).Trim() 
    } else { 
        $null 
    }
    $packageJson = Test-Path package.json -PathType Leaf
    $currentTime = $(Get-Date -Format "dddd dd-MM-yyyy HH:mm")
    $currentBranchIsModified = $false

    $gitStatus = git status --porcelain 2>$null
    $countModifiedFiles = (git status -s | Measure-Object -Line).Lines
    $modifiedInfo = git diff --shortstat

    if ($gitStatus -and $gitStatus.Trim()) {
        $currentBranchIsModified = $true
    }

    if ($Env:SHOW_PROMPT_TIME -eq "YES") {
        if ($uptime) {
            Write-Host "💻 Uptime: " -NoNewLine -ForegroundColor Gray
            Write-Host "$uptime, " -NoNewLine -ForegroundColor Magenta
        } else {
            Write-Host "💻 Uptime: Unknown " -NoNewLine -ForegroundColor Gray
        }
        Write-Host "⌚ $currentTime " -ForegroundColor Yellow
    }
    Write-Host "🫀 $username "  -NoNewLine -ForegroundColor Cyan
    Write-Host "📂 $folder " -NoNewLine -ForegroundColor Green

    if ($currentBranch) {
        Write-Host "🌵 git:" -NoNewLine -ForegroundColor White
        Write-Host $currentBranch -NoNewLine -ForegroundColor Yellow
        if ($currentBranchIsModified) {
            Write-Host " [M:$countModifiedFiles]" -NoNewLine -ForegroundColor Red
        }
    }

    if ($packageJson -and $nodeVersion) {
        Write-Host " [👽 $nodeVersion] " -NoNewLine -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "└─❯" -NoNewLine -ForegroundColor Yellow
    return " "
}

# Maven utils (for Binder projects)

function b-clean {
    mvn clean -f pom-sources.xml
}

function b-init-front {
    mvn initialize -f pom-sources.xml -Plocal-frontend-sources
}

function b-init-back {
    mvn initialize -f pom-sources.xml -Plocal-backend-sources
}

function b-init-all {
    mvn initialize -f pom-sources.xml -Plocal-backend-sources -Plocal-frontend-sources
}

function b-init-remote {
    mvn initialize -f pom-sources.xml
}

function b-install {
    mvn install
}

# NPM
function start {
    param (
        [string]$Script
    )

    if (-not $Script -or $Script.Trim() -eq '') {
        npm start
    } else {
        npm run "start:$Script"
    }
}

function dev {
    param (
        [string]$Script
    )

    if (-not $Script -or $Script.Trim() -eq '') {
        npm run dev
    } else {
        npm run "dev:$Script"
    }
}

function build {
        param (
        [string]$Script
    )
    if (-not $Script -or $Script.Trim() -eq '') {
        npm run build
    } else {
        npm run "build:$Script"
    }
}

function test {
        param (
        [string]$Script
    )
    if (-not $Script -or $Script.Trim() -eq '') {
        npm test
    } else {
        npm run "test:$Script"
    }
}

function lint {
        param (
        [string]$Script
    )
    if (-not $Script -or $Script.Trim() -eq '') {
        npm run lint
    } else {
        npm run "lint:$Script"
    }
}   

# Certificates
function create-localhost-conf {
    param (
        [string]$Path = "."
    )

    Write-Host "Creating localhost.conf..." -NoNewLine
    $confContent = @"
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = UA
ST = Ukraine
L = Kyiv
O = Development
OU = Development
CN = localhost

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = *.localhost
IP.1 = 127.0.0.1
IP.2 = ::1
"@

    $confFile = Join-Path -Path $Path -ChildPath "localhost.conf"

    try {
        $confContent | Out-File -FilePath $confFile -Encoding UTF8
        Write-Host "OK" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed" -ForegroundColor Red
    }
}

function create-localhost-cert {
    param (
        [string]$Path = ".",
        [string]$Name = "cert",
        [string]$Key = "key",
        [switch]$Import,
        [switch]$Admin,
        [switch]$Verbose
    )

    $confPath = Join-Path -Path $Path -ChildPath "localhost.conf"
    $certPath = Join-Path -Path $Path -ChildPath "$Name.pem"
    $keyPath = Join-Path -Path $Path -ChildPath "$Key.pem"

    Write-Host " "

    # Check if openssl is installed
    if (-not (Get-Command openssl -ErrorAction SilentlyContinue)) {
        Write-Host "OpenSSL is not installed or not found in PATH." -ForegroundColor Red
        return
    }

    # Create localhost.conf
    if (-not (Test-Path -Path "./localhost.conf")) {
        create-localhost-conf
    }

    # Generate a self-signed certificate for localhost 
    Write-Host "Generating certificate and key files..." -NoNewLine
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "$keyPath" -out "$certPath" -config "$confPath" -extensions v3_req 2>&1 | Out-Null

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed" -ForegroundColor Red
        return
    }

    Write-Host "OK" -ForegroundColor Green

    Write-Host "Certificate and private key created successfully!" -ForegroundColor Green
    
    if (-not $Import) {
        Write-Host " "
        return
    }

    Write-Host "Importing certificate to certificate store..."
    
    # Check if running as administrator
    $currentUserIsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    try {
        if ($Admin -and $currentUserIsAdmin) {
            # Method 1: Using Import-Certificate cmdlet for system store
            Write-Host "Importing to system certificate store using Import-Certificate..." -ForegroundColor Yellow
            Import-Certificate -FilePath "$certPath" -CertStoreLocation Cert:\LocalMachine\Root -Verbose:$Verbose
            Write-Host "Certificate imported successfully to system Trusted Root Certification Authorities." -ForegroundColor Green
            
        } elseif ($Admin -and -not $currentUserIsAdmin) {
            Write-Host "Admin import requested but PowerShell is not running as Administrator." -ForegroundColor Red
            Write-Host "Please restart PowerShell as Administrator or remove -Admin parameter." -ForegroundColor Yellow
            return            
        } else {
            # Method 2: Using Import-Certificate cmdlet for current user
            Write-Host "Importing to current user certificate store using Import-Certificate..." -ForegroundColor Yellow
            Import-Certificate -FilePath "$Name.pem" -CertStoreLocation Cert:\CurrentUser\Root -Verbose:$Verbose
            Write-Host "Certificate imported successfully to current user Trusted Root Certification Authorities." -ForegroundColor Green
            
            if (-not $Admin) {
                Write-Host "Note: Use -Admin parameter and run as Administrator for system-wide trust." -ForegroundColor Cyan
            }
        }
        
    } catch {
        # Fallback to manual .NET method if Import-Certificate fails
        Write-Host "Import-Certificate failed, trying alternative method..." -ForegroundColor Yellow
        
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $cert.Import("$Name.pem")

        if ($Admin -and $currentUserIsAdmin) {
            $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
        } else {
            $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "CurrentUser")
        }
        
        $store.Open("ReadWrite")
        $store.Add($cert)
        $store.Close()
        Write-Host "Certificate imported successfully using fallback method." -ForegroundColor Green
    }

    Write-Host " "
}

# Help
function help {
    param (
        [switch]$Git,
        [switch]$Linux,
        [switch]$Binder,
        [switch]$Utils,
        [switch]$Vars,
        [switch]$Certs,
        [switch]$All
    )

    $none = -not ($Git -or $Linux -or $Binder -or $Utils -or $Vars -or $Certs -or $All)

    Write-Host ""
    Write-Host "=== Pimenov's PowerShell Extensions ===" -ForegroundColor Cyan
    Write-Host ""

    if ($Git -or $All -or $none) {
        Write-Host "Git Helper Functions:" -ForegroundColor Yellow
        Write-Host "  init                         - Initialize git repository"
        Write-Host "  status                       - Show git status"
        Write-Host "  add <file>                   - Add files to staging"
        Write-Host "  branch                       - List branches"
        Write-Host "  diff                         - Show git diff"
        Write-Host "  pull                         - Pull from remote"
        Write-Host "  del-branch <branch>          - Delete local branch"
        Write-Host "  del-remote <branch>          - Delete remote branch"
        Write-Host "  clean                        - Clean untracked files"
        Write-Host "  reset                        - Reset changes"
        Write-Host "  reset-hard                   - Hard reset to HEAD"
        Write-Host "  unindex <name>               - Remove file from index"
        Write-Host "  clear-index                  - Remove all files from index"
        Write-Host "  current [-Verbose]           - Get current branch name"
        Write-Host "  fetch                        - Fetch all remotes"
        Write-Host "  fetch-remote [remote]        - Fetch specific remote (default: origin)"
        Write-Host "  fetch-prune [remote]         - Fetch and prune remote (default: origin)"
        Write-Host "  fetch-prune-tags             - Fetch and prune tags from all remotes"
        Write-Host "  fetch-prune-all              - Fetch, prune branches and tags from all remotes"
        Write-Host "  fetch-branch <branch>        - Fetch specific branch from remote (origin)"
        Write-Host "  checkout <branch>            - Checkout branch with smart search"
        Write-Host "  list <pattern>               - Search for local branches matching pattern"
        Write-Host "  list-remote <pattern>        - Search for remote branches matching pattern"
        Write-Host "  create <type> <name> [from]  - Create new branch (default from: master)"
        Write-Host "  rename <newName> [oldName]   - Rename branch"
        Write-Host "  exists <name> [remote]       - Check if branch exists"
        Write-Host "  merge <branch> [-Verbose]    - Merge source branch into target"
        Write-Host "  clone <repo> <target> [depth] - Clone repository"
        Write-Host "  clone-one <repo> <target>    - Clone repository with depth 1"
        Write-Host "  check [remote]               - Check if remote is reachable (default: origin)"
        Write-Host "  has-changes                  - Check if working tree has uncommitted changes (internal)"
        Write-Host "  update [branch]              - Pull changes for current or update from specified branch"
        Write-Host "  upstream <branch> [origin]   - Set upstream for branch"
        Write-Host "  commit [message]             - Add all and commit with message"
        Write-Host "  push <message> [remote]      - Commit and push changes to remote (default: origin)"
        Write-Host "  restore-from <name> [source] - Restore files (default source: master)"
        Write-Host "  restore [files...]           - Restore files (default: all)"
        Write-Host "  log [depth]                  - Show git log"
        Write-Host ""

        Write-Host "Git Workflow Functions:" -ForegroundColor Yellow
        Write-Host "  feature <name> [from]   - Create feature branch"
        Write-Host "  review <name> [from]    - Create review branch"
        Write-Host "  hotfix <name> [from]    - Create hotfix branch"
        Write-Host "  release <name> [from]   - Create release branch"
        Write-Host ""
    }

    if ($Linux -or $All -or $none) {
        Write-Host "Linux-style File Operations:" -ForegroundColor Green
        Write-Host "  ls [path] [pattern] [-C]     - List directory contents"
        Write-Host "  la [path] [pattern]          - List all files"
        Write-Host "  lf [path] [pattern]          - List all files including hidden"
        Write-Host "  lr [path] [pattern]          - List files recursively"
        Write-Host "  pwd                          - Show current directory"
        Write-Host "  cat <file>                   - Display file contents"
        Write-Host "  touch <path>                 - Create new file"
        Write-Host "  tail <file> [-Lines n] [-F]  - Show last n lines of file"
        Write-Host "  rn <path> <newName>          - Rename file or directory"
        Write-Host "  du [directory] [-K|-M]       - Show disk usage"
        Write-Host "  df [path] [-H|-K|-M|-T]      - Show disk free space"
        Write-Host "  search <path> <file>         - Search for files recursively"
        Write-Host "  which                        - Alias for search"
        Write-Host ""
        
        Write-Host "Enhanced grep Function:" -ForegroundColor Green
        Write-Host "  grep <pattern> [file]        - Search for pattern in file or pipeline input"
        Write-Host "    -IgnoreCase                - Ignore case when searching"
        Write-Host "    -CaseSensitive             - Force case-sensitive search"
        Write-Host "    -Regex                     - Use regular expressions"
        Write-Host "    -Invert                    - Show non-matching lines"
        Write-Host "    -Count                     - Count matching lines"
        Write-Host "    -LineNumber                - Show line numbers"
        Write-Host "    -Context <n>               - Show n lines around matches"
        Write-Host "    -Quiet                     - Return boolean (true if found)"
        Write-Host "    -Recurse                   - Search in directories recursively"
        Write-Host "    -Include <patterns>        - Include files matching pattern"
        Write-Host "    -Exclude <patterns>        - Exclude files matching pattern"
        Write-Host ""
        Write-Host "  Examples:"
        Write-Host "    cat file.txt | grep 'error'"
        Write-Host "    grep 'function' script.ps1 -LineNumber"
        Write-Host "    grep 'TODO' -Where . -Recurse -Include '*.ps1'"
        Write-Host "    Get-Process | grep 'chrome' -Count"
        Write-Host ""
    }

    if ($Utils -or $All -or $none) {
        Write-Host "Utility Functions:" -ForegroundColor Magenta
        Write-Host "  clear                        - Clear screen"
        Write-Host "  markdown <path>              - Display markdown file"
        Write-Host "  notepad <file>               - Open file in Notepad++"
        Write-Host "  errors [count]               - Show last n errors (default: 5)"
        Write-Host "  last-error                   - Show details of last error"
        Write-Host "  Format-Size <bytes>          - Convert bytes to readable size (internal)"
        Write-Host "  help [switches]              - Show this help"
        Write-Host "  extract-vscode-extensions [file] [-Install] [-Linux] - Export VS Code extensions"
        Write-Host ""
    }

    if ($Certs -or $All -or $none) {
        Write-Host "Certificate Functions:" -ForegroundColor Cyan
        Write-Host "  create-localhost-conf [path]    - Create localhost.conf for SSL certificates"
        Write-Host "  create-localhost-cert [options] - Create self-signed localhost certificate"
        Write-Host "    -Path <path>               - Directory for certificate files"
        Write-Host "    -Name <name>               - Certificate file name (default: cert)"
        Write-Host "    -Key <name>                - Private key file name (default: key)"
        Write-Host "    -Import                    - Import certificate to store"
        Write-Host "    -Admin                     - Import to system store (requires admin)"
        Write-Host "    -Verbose                   - Show detailed output"
        Write-Host ""
    }

    if ($Binder -or $All -or $none) {
        Write-Host "Binder Project Functions (maven):" -ForegroundColor Blue
        Write-Host "  b-clean                      - Clean binder project"
        Write-Host "  b-init-front                 - Initialize frontend sources"
        Write-Host "  b-init-back                  - Initialize backend sources"
        Write-Host "  b-init-all                   - Initialize all sources"
        Write-Host "  b-init-remote                - Initialize remote sources"
        Write-Host "  b-install                    - Install binder project"
        Write-Host ""
    }

    if ($Vars -or $All -or $none) {
        Write-Host "Environment Variables:" -ForegroundColor Cyan
        Write-Host "  SHOW_PROMPT_TIME             - Set to 'YES' to show time and uptime in prompt"
        Write-Host ""
        
        Write-Host "Additional Tools:" -ForegroundColor Yellow
        Write-Host "  nvm                          - Node Version Manager wrapper (Windows/Linux/macOS)"
        Write-Host "  Initialize-NvmPath           - Initialize NVM-related PATH variables (internal)"
        Write-Host "  prompt                       - Custom shell prompt function"
        Write-Host ""
        
        Write-Host "Custom Prompt Features:" -ForegroundColor Yellow
        Write-Host "  🫀 Username                  - Current user"
        Write-Host "  📂 Folder                    - Current directory"
        Write-Host "  🌵 Git Branch                - Current git branch with modification status"
        Write-Host "  👽 Node Version              - Node.js version (if package.json exists)"
        Write-Host "  💻 Uptime                    - System uptime (if SHOW_PROMPT_TIME=YES)"
        Write-Host "  ⌚ Date/Time                 - Current date and time (if SHOW_PROMPT_TIME=YES)"
        Write-Host ""
    }

    Write-Host "Usage: help [-Git] [-Linux] [-Utils] [-Certs] [-Binder] [-Vars] [-All]" -ForegroundColor Gray
    Write-Host ""
}

# Перевірка та інсталяція модуля Terminal-Icons
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Write-Host "Installing Terminal-Icons module..." -ForegroundColor Yellow
    Install-Module -Name Terminal-Icons -Force -Scope CurrentUser
}
Import-Module -Name Terminal-Icons

# PSReadLine configuration for predictive suggestions
if (-not (Get-Module -ListAvailable -Name PSReadLine)) {
    Install-PSResource -Name PSReadLine -Force -Scope CurrentUser
}

if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    
    # Увімкнення автодоповнення команд
    Set-PSReadLineOption -PredictionSource History
    
    # Налаштування стилю відображення через змінну середовища
    # Можливі значення: InlineView, ListView
    $predictionViewStyle = if ($env:PREDICTION_VIEW_STYLE) { 
        $env:PREDICTION_VIEW_STYLE 
    } else { 
        "InlineView" 
    }
    Set-PSReadLineOption -PredictionViewStyle $predictionViewStyle
    
    Set-PSReadLineOption -EditMode Windows
    
    # Клавіші для навігації по пропозиціях
    Set-PSReadLineKeyHandler -Key "Ctrl+f" -Function ForwardWord
    Set-PSReadLineKeyHandler -Key "Ctrl+RightArrow" -Function AcceptNextSuggestionWord
    Set-PSReadLineKeyHandler -Key RightArrow -Function ForwardChar
    Set-PSReadLineKeyHandler -Key Tab -Function Complete
}

# Fixes

# Enable nvm cross-platform
function Initialize-NvmPath {
    if ($IsLinux -or $IsMacOS) {
        $ENV:NVM_DIR = "$HOME/.nvm"
        if (Test-Path "$HOME/.nvm/nvm.sh") {
            $bashPathWithNvm = bash -c 'source $NVM_DIR/nvm.sh && echo $PATH'
            $env:PATH = $bashPathWithNvm
        }
    } elseif ($IsWindows) {
        # Check for nvm-windows installation
        $nvmWindowsPath = "$env:APPDATA\nvm"
        if (Test-Path $nvmWindowsPath) {
            $env:NVM_HOME = $nvmWindowsPath
            $env:NVM_SYMLINK = "$env:APPDATA\nodejs"
            if ($env:PATH -notlike "*$nvmWindowsPath*") {
                $env:PATH = "$nvmWindowsPath;$env:PATH"
            }
        }
    }
}

function nvm {
    if ($IsLinux -or $IsMacOS) {
        # Linux/macOS implementation using bash
        $quotedArgs = ($args | ForEach-Object { "'$_'" }) -join ' '
        $command = 'source $NVM_DIR/nvm.sh && nvm {0}' -f $quotedArgs
        bash -c $command
    } elseif ($IsWindows) {
        # Windows implementation
        $nvmExe = Get-Command "nvm.exe" -ErrorAction SilentlyContinue
        if ($nvmExe) {
            & nvm.exe $args
        } else {
            Write-Host "nvm is not installed on Windows." -ForegroundColor Red
            Write-Host "Please install nvm-windows from: https://github.com/coreybutler/nvm-windows" -ForegroundColor Yellow
            Write-Host "Or use alternative: scoop install nvm" -ForegroundColor Cyan
        }
    } else {
        Write-Host "Unsupported operating system for nvm function." -ForegroundColor Red
    }
}

# Initialize nvm for all platforms
if ($IsLinux -or $IsMacOS) {
    if (Test-Path "$HOME/.nvm/nvm.sh") {
        Initialize-NvmPath
    }
} elseif ($IsWindows) {
    Initialize-NvmPath
}

# Enable rust in linux
if ($IsLinux -and (Test-Path "$HOME/.cargo/env")) {
    $cargoEnv = bash -c "source $HOME/.cargo/env && env"
    $cargoEnv | ForEach-Object {
        if ($_ -match "^PATH=(.*)$") {
            $env:PATH = $matches[1]
        }
    }
}
