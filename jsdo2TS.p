
/*------------------------------------------------------------------------
    File        : jsdo2TS.p
    Purpose     : 

    Syntax      :

    Description : Convert JSDO catalog (v1.5) to TS class definition

    Author(s)   : rdroge
    Created     : Sat Feb 24 08:25:52 CET 2018
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

using Progress.Json.ObjectModel.*.
using Progress.Lang.Object.

define temp-table TypeScript
field servicename   as character
field fieldname     as character
field datatype      as character
.

/* ***************************  Main Block  *************************** */
define variable joJSDO      as JsonObject   no-undo.
define variable joServices  as JsonArray    no-undo.
define variable joResources as JsonObject   no-undo.
define variable joFields    as JsonObject   no-undo.
define variable joField     as JsonObject   no-undo.
define variable poObject    as object       no-undo.
define variable servicename as character    no-undo.

define variable ompParser   as ObjectModelParser    no-undo.
define variable arNames     as character extent     no-undo.
define variable iService    as integer              no-undo.
define variable iField      as integer              no-undo.

ompParser = new ObjectModelParser().
//Parse JSDO file as a JsonObject
joJSDO = cast(ompParser:ParseFile("c:\temp\TechProfilesJSDO.json"), JsonObject).

//Get to the part where the various resources are defined (Business Entities)
joServices = joJSDO:GetJsonArray("services"):GetJsonObject(1):GetJsonArray("resources").

//Walk through the resources
do iService=1 to joServices:length:
    //get the resource name
    servicename = joServices:getJsonObject(iService):getCharacter("name").
    joResources = joServices:getJsonObject(iService):getJsonObject("schema").
    //get to the part where field names are for the resource
    do while joResources:Has("items") = false:
        poObject = joResources:next-sibling.
        joResources = cast(poObject, JsonObject).     
    end.
    
    joFields = joResources:getJsonObject("items"):getJsonObject("properties").
    //get the field names of the resource into an array
    arNames = joFields:getNames().
    
    //walk through the array and create temp-table records 
    do iField=1 to extent(arNames):
        joField = joFields:getJsonObject(arNames[iField]).
        create TypeScript.
            assign 
                TypeScript.servicename  = servicename
                TypeScript.fieldname    = arNames[iField]
                TypeScript.datatype     = joField:GetCharacter("type")
                .
    end.
    //empty the array for the next resource
    extent(arNames) = ?.
    //export the content of the temp-table to a TypeScript file
    output to value("c:\temp\" + servicename + ".ts").
        message "export class " + servicename + " " + CHR(123) skip.
        for each TypeScript:
            message "   public " + TypeScript.fieldname + ": " + TypeScript.Datatype + ";" skip.
        end.
        message chr(125).     
    output close.
    //empty the temp-table for the next resource
    empty temp-table TypeScript.
end.
            




