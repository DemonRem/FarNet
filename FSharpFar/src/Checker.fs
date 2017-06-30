﻿
// FarNet module FSharpFar
// Copyright (c) Roman Kuzmin

module FSharpFar.Checker

open System
open System.IO
open Config
open Options
open Session
open FsAutoComplete
open Microsoft.FSharp.Compiler.SourceCodeServices

type CheckFileResult = {
    Checker: FSharpChecker
    Options: FSharpProjectOptions
    ParseResults: FSharpParseFileResults
    CheckResults: FSharpCheckFileResults
}

let check file text options = async {
    let checker =
        let msbuild = match options with ProjectOptions _ -> true | _ -> false
        FSharpChecker.Create (msbuildEnabled = msbuild)

    let! projOptions = async {
        match options with
            | ProjectOptions options ->
                return options
            | ConfigOptions config ->
                // get script options combined with ini, needed for #I, #r and #load in the script
                let otherFlags = [|
                    // our predefined
                    yield! getCompilerOptions ()
                    // user fsc
                    yield! config.FscArgs
                |]
                //TODO use `errors`, FSC 12.0.2
                let! projOptionsFile, errors = checker.GetProjectOptionsFromScript (file, text, otherFlags = otherFlags)

                let files = ResizeArray ()
                let addFiles arr =
                    for f in arr do
                        let f1 = Path.GetFullPath f
                        if files.FindIndex (fun x -> f1.Equals (x, StringComparison.OrdinalIgnoreCase)) < 0 then
                            files.Add f1

                addFiles config.LoadFiles
                addFiles config.UseFiles
                // #load files and the file itself
                addFiles projOptionsFile.ProjectFileNames
                
                let args = [|
                    // "default" options and references
                    yield! projOptionsFile.OtherOptions
                    // our files
                    yield! files
                |]
                return checker.GetProjectOptionsFromCommandLineArgs (file, args)
    }
    
    let! parseResults, checkAnswer = checker.ParseAndCheckFileInProject (file, 0, text, projOptions)
    let checkResults =
        match checkAnswer with
        | FSharpCheckFileAnswer.Succeeded x -> x
        | _ -> invalidOp "Unexpected checker abort."

    return {
        Checker = checker
        Options = projOptions
        ParseResults = parseResults
        CheckResults = checkResults
    }
}

let strTip tip =
    use w = new StringWriter ()

    let data = TipFormatter.formatTip tip
    for list in data do
        for (signature, comment) in list do
            w.WriteLine signature
            if not (String.IsNullOrEmpty comment) then
                if not (comment.StartsWith Environment.NewLine) then
                    w.WriteLine ()
                w.WriteLine (strZipSpace comment)

    w.ToString ()
