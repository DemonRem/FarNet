<#
.Synopsis
	Editor profile (example).
	Author: Roman Kuzmin

.Description
	The profile should be in %FARPROFILE%\FarNet\PowerShellFar

	This is an example of the editor profile which is invoked when an editor is
	opened the first time. It installs some key and mouse handles. Before using
	read the help "Profile-Editor.ps1" and the code.
#>

### Editor data. This line also denies the second call, it fails.
New-Variable Editor.Data @{} -Scope Global -Option ReadOnly -Description 'Editor handlers data.' -ErrorAction Stop

### GotFocus handler; it resets old data
$Far.AnyEditor.add_GotFocus({
	${Editor.Data}.Clear()
})

### Key down handler
$Far.AnyEditor.add_KeyDown({
	### F1
	if ($_.Key.Is([FarNet.KeyCode]::F1)) {
		if ($this.FileName -like '*.hlf') {
			$_.Ignore = $true
			Show-Hlf-.ps1
		}
		elseif ($this.FileName -match '\.(?:text|md|markdown)$') {
			$_.Ignore = $true
			Show-Markdown-.ps1 -Help
		}
	}
})

### Mouse click handler
$Far.AnyEditor.add_MouseClick({
	$m = $_.Mouse
	### Left click
	if ($m.Buttons -eq 'Left') {
		if ($m.Is()) {
			${Editor.Data}.LCPos = $this.ConvertPointScreenToEditor($m.Where)
			${Editor.Data}.LMFoo = 1
		}
		elseif ($m.IsShift()) {
			$_.Ignore = $true
			${Editor.Data}.LMFoo = 1
			$p1 = ${Editor.Data}.LCPos
			if (!$p1) {
				$p1 = $this.Caret
			}
			$p2 = $this.ConvertPointScreenToEditor($m.Where)
			$this.SelectText($p1.X, $p1.Y, $p2.X, $p2.Y)
			$this.Redraw()
		}
	}
	### Right click
	elseif ($m.Buttons -eq 'Right') {
		if ($m.Is()) {
			$_.Ignore = $true
			$Editor = $this
			$SelectionExists = $this.SelectionExists
			New-FarMenu -Show -AutoAssignHotkeys -X $m.Where.X -Y $m.Where.Y -Items @(
				New-FarItem 'Cut' { $Far.CopyToClipboard($Editor.GetSelectedText()); $Editor.DeleteText() } -Disabled:(!$SelectionExists)
				New-FarItem 'Copy' { $Far.CopyToClipboard($Editor.GetSelectedText()) } -Disabled:(!$SelectionExists)
				New-FarItem 'Paste' { if ($SelectionExists) { $Editor.DeleteText() } $Editor.InsertText($Far.PasteFromClipboard()) }
			)
		}
	}
})

### Mouse move handler
$Far.AnyEditor.add_MouseMove({
	$m = $_.Mouse
	### Left moved
	if ($m.Buttons -eq 'Left') {
		# [_090406_225257] skip the 1st move after some mouse actions
		#  ??? workaround, to remove when fixed in Far or FarNet
		if (${Editor.Data}.LMFoo) {
			$_.Ignore = $true
			${Editor.Data}.LMFoo = 0
		}
		elseif ($m.Is()) {
			$p1 = ${Editor.Data}.LCPos
			if ($p1) {
				$_.Ignore = $true
				$p2 = $this.ConvertPointScreenToEditor($m.Where)
				$this.SelectText($p1.X, $p1.Y, $p2.X, $p2.Y)
				$this.Redraw()
			}
		}
	}
})
