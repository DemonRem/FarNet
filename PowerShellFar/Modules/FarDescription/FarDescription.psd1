@{
	Author = 'Roman Kuzmin'
	ModuleVersion = '1.0.0'
	CompanyName = 'https://github.com/nightroman/FarNet'
	Description = 'Far Manager file description tools.'
	Copyright = 'Copyright (c) Roman Kuzmin'

	NestedModules = 'FarDescription.dll'
	ModuleToProcess = 'FarDescription.psm1'
	RequiredAssemblies = 'FarDescription.dll'
	TypesToProcess = @('FarDescription.Types.ps1xml')

	CLRVersion = '2.0.50727'
	PowerShellVersion = '2.0'
	GUID = '{1e7f7fc4-59c4-48c6-8847-bddef25458dd}'
}
