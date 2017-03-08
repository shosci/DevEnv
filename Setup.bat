@echo off
:: ========check permissions========
echo Admin permission required.
echo Checking...
net session >nul 2>&1
if %errorlevel% neq 0 (
	call :print_failure "Inadequate permission, please run as Admin"
	pause >nul
	exit /b
)
call :print_success "Permission check pass"

:: ========check prerequisites========
::
:: ========1. chocolatey========
echo Chocolatey required.
echo Checking...
choco -v >nul 2>&1
if %errorlevel% neq 0 (
	::call :print_failure "Chocolatey is not installed, install it from https://chocolatey.org"
	::pause >nul
	::exit /b
	echo Chocolatey is not intalled, installing...
	powershell "Set-ExecutionPolicy -Scope Process -ExecutionPolicy ByPass; iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex; exit;"
) else (
	call :print_success "Choco check pass"
)

:: ========2. GitHub========
:: TODO - remove this prerequisite and make git installation part of this script
echo Git required.
echo Checking...
if not exist "%LOCALAPPDATA%\GitHub\" (
	:: Choco doesn't have a stable packacke for git yet, manual installation from github is recommended.
	:: choco install /y git/git.install/github none of them seemed good enough
	call :print_failure "Please intall GitHub Desktop from https://desktop.github.com/"
	pause >nul
	exit /b
)

:: ========install GnuWin========
awk --version >nul 2>&1
if %errorlevel% neq 0 (
	echo Install GnuWin by 'choco /y gnuwin'
	choco install /y gnuwin
	if %errorlevel% neq 0 (
		call :print_failure "Install GnuWin failed"
		pause >nul
		exit /b
	) else (
		echo adding GnuWin to system path
		setx PATH "%PATH%;C:\GnuWin\bin" -m
		echo adding GnuWin to PATH for this session
		set "PATH=%PATH%;C:\GnuWin\bin"
	)
)
call :print_success "GnuWin installed"

:: currently detecting git install path used GnuWin tools, so install GnuWin before git install path detection
echo detect if git is in system path
git --version >nul 2>&1
if %errorlevel% neq 0 (
	call :print_warning "git is not in system path"
	echo detecting git install path...
	for /f "tokens=*" %%f in ('dir %LOCALAPPDATA%\GitHub ^| grep PortableGit ^| awk "{print $5;}"') do set GitPath=%%f
	if defined GitPath (
		echo git install path detected: %LocalAppData%\GitHub\%GitPath% 
		echo adding git into system path...
		setx PATH "%PATH%;%LocalAppData%\GitHub\%GitPath%\cmd" -m
		echo adding git into path for this session
		set "PATH=%PATH%;%LocalAppData%\GitHub\%GitPath%\cmd"
	) else (
		call :print_failure "Didn't detect git install path, it should be like %LocalAppData%\GitHub\PortableGit_XXX"
		pause >nul
		exit /b
	)
) else (
	echo git is already in system path
)
call :print_success "Git check pass"

:: ========install VIM========
echo detect if VIM installed
vim --version >nul 2>&1
if %errorlevel% neq 0 (
	echo VIM not installed, install it by 'choco install /y vim-tux.portable'
	choco install /y vim-tux.portable
	if %errorlevel% neq 0 (
		call :print_failure "Install VIM failed"
		pause >nul
		exit /b
	)
	call :print_success "VIM installed"
) else (
	echo VIM is already installed
)

:: ========setup for VIM========
echo remove original _vimrc by 'del /q %UserProfile%\_vimrc'
del /q %UserProfile%\_vimrc

:: ========git clone proper vim setting projects========
echo setup root directory for vim settings projects
if exist %UserProfile%\GitHub\ (
	echo %UserProfile%\GitHub exists
) else (
	echo %UserProfile%\GitHub doesn't exist, creating...
	mkdir %UserProfile%\GitHub
	echo %UserProfile%\GitHub created
)
echo change directory to %UserProfile%\GitHub
cd /d %UserProfile%\GitHub

echo clone vimrc project
git clone https://github.com/shosci/vim.git

echo make a link to vimrc
mklink %UserProfile%\_vimrc %UserProfile%\GitHub\vim\vimrc\vimrc

echo detect if %UserProfile%\vimfiles
if exist %UserProfile%\vimfiles\ (
	echo %UserProfile%\vimfiles exists
) else (
	echo %UserProfile%\vimfiles doesn't exist, creating...
	mkdir %UserProfile%\vimfiles
	echo %UserProfile%\vimfiles created
)
cd /d %UserProfile%\vimfiles
echo clone pathogen
git clone https://github.com/tpope/vim-pathogen.git
mklink /D autoload vim-pathogen\autoload
echo mkdir bundle since other plugin will be placed there
mkdir bundle

cd bundle
echo clone solarized color
git clone https://github.com/altercation/vim-colors-solarized.git

echo clone aireline project
git clone https://github.com/vim-airline/vim-airline.git

:: ========install ConEmu========
echo Install ConEmu by 'choco /y conemu'
choco install /y conemu

if %errorlevel% neq 0 (
	call :print_failure "Install ConEmu failed"
	pause >nul
	exit /b
)
call :print_success "ConEmu installed"

call :print_success "Congrats! All installation passed!"
goto :eof

rem escaped colors require win10 threshhold 2 update
rem https://gist.github.com/mlocati/fdabcaeb8071d5c75a2d51712db24011#file-win10colors-cmd
:print_failure message
:: message - failure message to print
	echo [91m Failure: %~1. [0m
	exit /b

:print_success message
:: message - success message to print
	echo [32m Success: %~1. [0m
	exit /b

:print_warning message
:: message - warning message to print
	echo [93m Success: %~1. [0m
	exit /b
