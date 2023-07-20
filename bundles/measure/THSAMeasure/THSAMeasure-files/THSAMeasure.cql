library THSAMeasure version '1.0.0'

using FHIR version '4.0.1'

include MATGlobalCommonFunctionsFHIR4 version '6.1.000' called Global
include SupplementalDataElementsFHIR4 version '2.0.000' called SDE
include FHIRHelpers version '4.0.1' called FHIRHelpers

//codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
//codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "LocationPhysicalType": 'http://terminology.hl7.org/CodeSystem/location-physical-type'
codesystem "EpicEncounterTypes": 'urn:oid:1.2.840.114350.1.13.68.2.7.10.698084.10110'
codesystem "EpicEncounterClasses": 'urn:oid:1.2.840.114350.1.72.1.7.7.10.696784.13260'

//valueset "Healthcare Service Locations": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.1.11.20275'
//valueset "ICU Locations": 'http://hl7.org/fhir/uv/saner/ValueSet/ICULocations'
//valueset "Inpatient Locations": 'http://hl7.org/fhir/uv/saner/ValueSet/InpatientLocations'
valueset "COVID_19 (COVID_19 Exposure) (SNOMED)": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1146.1203'
valueset "COVID_19 (Disorders) (ICD10CM)": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1146.1123'
valueset "COVID_19 (Disorders) (SNOMED)": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1146.1124'
//valueset "Ventilator Devices": 'http://hl7.org/fhir/uv/saner/ValueSet/VentilatorDevices'
//valueset "Ventilator Observations": 'http://hl7.org/fhir/uv/saner/ValueSet/VentilatorObservations'
//valueset "Ventilator Procedures": 'http://hl7.org/fhir/uv/saner/ValueSet/VentilatorProcedures'
//valueset "Patient Died": 'http://hl7.org/fhir/uv/saner/ValueSet/PatientDeaths'

code "Bed": 'bd' from "LocationPhysicalType" display 'Bed'
//code "ICU Location": '309904001' from "SNOMEDCT" display 'Intensive care unit (environment)'
//code "Inpatient Location": '440654001' from "SNOMEDCT" display 'Inpatient environment (environment)'
//code "inpatient acute": 'ACUTE' from "ActCode" display 'inpatient acute'
//code "inpatient encounter": 'IMP' from "ActCode" display 'inpatient encounter'
//code "inpatient non-acute": 'NONAC' from "ActCode" display 'inpatient non-acute'
code "inpatient type": '1' from "EpicEncounterTypes" display 'inpatient type'
code "admission class": '3' from "EpicEncounterClasses" display 'admission class'
code "discharge class": '6' from "EpicEncounterClasses" display 'discharge class'

parameter "Measurement Period" Interval<DateTime>
    default Interval[@2022-06-08T00:00:00.0, @2023-06-08T23:59:59.0)

context Patient

define "PatientAge":
    AgeInYearsAt(start of "Measurement Period")

define "Initial Population":
    "In Progress or Completed Inpatient Encounters"

define "In Progress or Completed Inpatient Encounters":
    [Encounter: class in {"admission class","discharge class"}] Encounters
        where Encounters.status in { 'finished', 'in-progress' }
        and true in "Check For Inpatient Encounter Type"(Encounters)
        and Encounters.period ends during "Measurement Period"

/*
define "In Progress or Completed Confirmed or Suspected COVID19 Encounters":
  [Encounter: class in {"inpatient encounter", "inpatient acute", "inpatient non-acute"}] Encounters
    where (
        exists(
            "COVID19 Diagnoses" COVID19Diagnoses
            where Global."Prevalence Period"(COVID19Diagnoses) overlaps Encounters.period
        ) or exists(
            "COVID19 Flags" COVID19Flags
            where COVID19Flags.period overlaps Encounters.period
        )
    )
    and Encounters.period ends during "Measurement Period"
    and Encounters.status in { 'finished', 'in-progress' }
*/

define "In Progress or Completed Inpatient Encounters with Confirmed or Suspected COVID19":
    [Encounter: class in {"admission class","discharge class"}] Encounters
        where Encounters.status in { 'finished', 'in-progress' }
        and true in "Check For Inpatient Encounter Type"(Encounters)
        and Encounters.period ends during "Measurement Period"
        and (
            exists(
                "COVID19 Diagnoses" COVID19Diagnoses
                where Global."Prevalence Period"(COVID19Diagnoses) overlaps Encounters.period
            ) 
            or exists(
                "COVID19 Flags" COVID19Flags
                where COVID19Flags.period overlaps Encounters.period
            )
        )

define "COVID19 Diagnoses": 
    [Condition: "COVID_19 (Disorders) (SNOMED)"]
    union [Condition: "COVID_19 (Disorders) (ICD10CM)"]
    union [Condition: "COVID_19 (COVID_19 Exposure) (SNOMED)"]

define "COVID19 Flags": 
    [Flag: "COVID_19 (Disorders) (SNOMED)"]
    union [Flag: "COVID_19 (Disorders) (ICD10CM)"]
    union [Flag: "COVID_19 (COVID_19 Exposure) (SNOMED)"]

define "Denominator": 
    "Initial Population"

/*
define "OLD Bed in Hospital Location": 
    "Initial Population" IP

    where exists(
        IP.location IPLocation
        where true in "Check for Inpatient Hospital Location"(Global.GetLocation(IPLocation.location))
    )

    and exists(
        IP.type types
        where types ~ "Inpatient Location" or types ~ "ICU Location"
    )

    and exists(
        IP.location IPLocation
        where IPLocation.physicalType ~ "Bed"
    )
*/

define function "Check For Inpatient Encounter Type"(encounter Encounter):
    encounter.type encTypes
    return (encTypes ~ "inpatient type")

/*
define function "Check for Inpatient Hospital Location"(location Location):
    location.type types
    return (
        types ~ "Inpatient Location" 
        or types ~ "ICU Location"
    )

define function "Check for ICU Hospital Location"(location Location):
    location.type types
    return types ~ "ICU Location"
*/

define "Numerator 1": 
    "Initial Population" IP

    where exists(
        IP.location IPLocation
        where IPLocation.physicalType ~ "Bed"
    )

define "Stratifier 2": 
    "Initial Population" InitialPopulation
    where exists(
            "COVID19 Diagnoses" COVID19Dx
            where Global."Normalize Interval"(COVID19Dx.onset) starts 14 days or more after start of InitialPopulation.period
            or Global."Normalize Interval"(COVID19Dx.onset) starts before end of InitialPopulation.period)
        or exists(
            "COVID19 Flags" COVID19Flags
            where COVID19Flags.period starts 14 days or more after start of InitialPopulation.period
            or COVID19Flags.period starts before end of InitialPopulation.period
        )

define "Numerator 2": 
    "Initial Population" InitialPopulation

    where exists(
        InitialPopulation.location loc
        where loc.location.reference ~ 'Location/eVMRCa.HAjzG-vMGRSJMFKQ3'
        or loc.location.reference ~ 'Location/e1f.FE8SwfX-QWcLcMxn-fQ3'
        or loc.location.reference ~ 'Location/e5UV0fFVck9t2AoKZTbRPSQ3'
        or loc.location.reference ~ 'Location/erYSPKXOCD3.OojjrJOgkgQ3'
        or loc.location.reference ~ 'Location/emDWszriZvC5TuMi4l8fWhA3'
        or loc.location.reference ~ 'Location/e2174iRNqlYR4CWT-agCAVw3'
        or loc.location.reference ~ 'Location/eK3oL9aTOs757RL166OF6mQ3'
        or loc.location.reference ~ 'Location/e39Y-sPslAZgn1zs68fNMtQ3'
        or loc.location.reference ~ 'Location/eT2iWRXYGSazBxtDnrcLlZA3'
        or loc.location.reference ~ 'Location/eXjJpL6A95mvWrHsNJztmHg3'
        or loc.location.reference ~ 'Location/eqSRRsUgo4Lm5AVbeUlXOfw3'
        or loc.location.reference ~ 'Location/elaCb5W0tc17nqQi4nWWaQw3'
        or loc.location.reference ~ 'Location/e4Ari1l1Wl87h5gF88VaxiQ3'
        or loc.location.reference ~ 'Location/eChXXcCOucRaM3eLsSQp2kw3'
        or loc.location.reference ~ 'Location/eeA.2iioiQ.bkkfbMapxn6g3'
        /*
        where loc.location.display ~ 'FIFTEEN NS ICU'
        or loc.location.display ~ 'FIVE SURG ICU'
        or loc.location.display ~ 'FIFTEEN SURG ICU'
        or loc.location.display ~ 'SIX BURN ICU'
        or loc.location.display ~ 'Fifteen CV ICU'
        or loc.location.display ~ 'FOUR NICU'
        or loc.location.display ~ 'TEN SOUTH CARDIO PULM ICU'
        or loc.location.display ~ 'NINE NORTH MEDICAL ICU'
        or loc.location.display ~ 'SIXTEEN NS ICU/PCU'
        or loc.location.display ~ 'Two N Trauma Surg ICU D'
        or loc.location.display ~ 'Two N Trauma Surg ICU C'
        or loc.location.display ~ 'Two N Surg ICU A'
        or loc.location.display ~ 'Sixteen TCU ICU'
        or loc.location.display ~ 'Two N Neuro Surg ICU B'
        */
    )
    and exists(
        InitialPopulation.location IPLocations
        where IPLocations.physicalType ~ "Bed"
    )

define "Sex Stratifier": 
    SDE."SDE Sex"

define "Race Stratifier": 
    SDE."SDE Race"

define "Ethnicity Stratifier": 
    SDE."SDE Ethnicity"

define "Age Stratifier 10-19": 
    "Initial Population" InitialPopulation
    where PatientAge >= 10 and PatientAge < 20

define "Age Stratifier 20-29": 
    "Initial Population" InitialPopulation
    where PatientAge >= 20 and PatientAge < 30

define "Age Stratifier 30-39": 
    "Initial Population" InitialPopulation
    where PatientAge >= 30 and PatientAge < 40

define "Age Stratifier 40-49": 
    "Initial Population" InitialPopulation
    where PatientAge >= 40 and PatientAge < 50

define "Age Stratifier 50-59": 
    "Initial Population" InitialPopulation
    where PatientAge >= 50 and PatientAge < 60

define "Age Stratifier 60-69": 
    "Initial Population" InitialPopulation
    where PatientAge >= 60 and PatientAge < 70

define "Age Stratifier 70-79": 
    "Initial Population" InitialPopulation
    where PatientAge >= 70 and PatientAge < 80

define "Age Stratifier 80-89": 
    "Initial Population" InitialPopulation
    where PatientAge >= 80 and PatientAge < 90

define "Age Stratifier 90-99": 
    "Initial Population" InitialPopulation
    where PatientAge >= 90 and PatientAge < 100