use master
go
set nocount on
go

if db_id('OMOP') is null
begin
    create database omop

    print 'Created database [OMOP]'
end
go

use omop
go
if schema_id('Athena') is null
begin
	exec (N'create schema [Athena]')
	print N'created schema [Athena]'
end
go

/*****************************
My Additions:

* Added DB creation statement
* Formatted the results 
* Added drop if exist statements
*****************************/
/*********************************************************************************
# Copyright 2018-08 Observational Health Data Sciences and Informatics
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
********************************************************************************/
/************************
 ####### #     # ####### ######      #####  ######  #     #            #####        ###
 #     # ##   ## #     # #     #    #     # #     # ##   ##    #    # #     #      #   #
 #     # # # # # #     # #     #    #       #     # # # # #    #    # #           #     #
 #     # #  #  # #     # ######     #       #     # #  #  #    #    # ######      #     #
 #     # #     # #     # #          #       #     # #     #    #    # #     # ### #     #
 #     # #     # #     # #          #     # #     # #     #     #  #  #     # ###  #   #
 ####### #     # ####### #           #####  ######  #     #      ##    #####  ###   ###

sql server script to create OMOP common data model version 6.0

last revised: 27-Aug-2018

Authors:  Patrick Ryan, Christian Reich, Clair Blacketer
*************************/
/*****************************
Creating ETL Principals
*****************************/
declare 
	@login nvarchar(128) = 'ohdsi_etl',
	@password nvarchar(128) = '0hds!_etl1',
	@user nvarchar(128) = 'ohdsi_etl',
	@sql nvarchar(max)
	 
select @sql = concat
(
	'drop user if exists ', quotename(@user), '
	if exists (select 1 from sys.server_principals where name = ', quotename(@login, ''''), ')
		drop login ', quotename(@login), '

	create login ', quotename(@login), ' with PASSWORD = ', quotename(@password, ''''), '
	raiserror(''Created login: %s'', 0, 1, ', quotename(@login, ''''), ') with nowait

	create user ', quotename(@user), ' for login ', quotename(@login), ' with default_schema = [Athena]
	raiserror(''Created user: %s'', 0, 1, ', quotename(@user, ''''), ') with nowait
	
	grant insert, update, delete, alter, select to ', quotename(@user)
)
exec sp_executesql @stmt = @sql
grant connect to ohdsi_etl

GO
/************************
Standardized vocabulary
************************/
--HINT DISTRIBUTE ON RANDOM
drop table if exists Athena.concept
raiserror('Created table: Athena.concept', 0, 1) with nowait
create table Athena.concept
(
    concept_id varchar(8000)null,
    concept_name varchar(8000)null,
    domain_id varchar(8000)null,
    vocabulary_id varchar(8000)null,
    concept_class_id varchar(8000)null,
    standard_concept varchar(8000)null,
    concept_code varchar(8000)null,
    valid_start_date varchar(8000)null,
    valid_end_date varchar(8000)null,
    invalid_reason varchar(8000)null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists Athena.vocabulary
raiserror('Created table: Athena.vocabulary', 0, 1) with nowait
create table Athena.vocabulary
(
    vocabulary_id varchar(8000)null,
    vocabulary_name varchar(8000)null,
    vocabulary_reference varchar(8000)null,
    vocabulary_version varchar(8000)null,
    vocabulary_concept_id varchar(8000)null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists Athena.domain
raiserror('Created table: Athena.domain', 0, 1) with nowait
create table Athena.domain
(
    domain_id varchar(8000)null,
    domain_name varchar(8000)null,
    domain_concept_id varchar(8000)null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists Athena.concept_class
raiserror('Created table: Athena.concept_class', 0, 1) with nowait
create table Athena.concept_class
(
    concept_class_id varchar(8000)null,
    concept_class_name varchar(8000)null,
    concept_class_concept_id varchar(8000)null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists Athena.concept_relationship
raiserror('Created table: Athena.concept_relationship', 0, 1) with nowait
create table Athena.concept_relationship
(
    concept_id_1 varchar(8000)null,
    concept_id_2 varchar(8000)null,
    relationship_id varchar(8000)null,
    valid_start_date varchar(8000)null,
    valid_end_date varchar(8000)null,
    invalid_reason varchar(8000)null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists Athena.relationship
raiserror('Created table: Athena.relationship', 0, 1) with nowait
create table Athena.relationship
(
    relationship_id varchar(8000)null,
    relationship_name varchar(8000)null,
    is_hierarchical varchar(8000)null,
    defines_ancestry varchar(8000)null,
    reverse_relationship_id varchar(8000)null,
    relationship_concept_id varchar(8000)null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists Athena.concept_synonym
raiserror('Created table: Athena.concept_synonym', 0, 1) with nowait
create table Athena.concept_synonym
(
    concept_id varchar(8000)null,
    concept_synonym_name varchar(8000)null,
    language_concept_id varchar(8000)null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists Athena.concept_ancestor
raiserror('Created table: Athena.concept_ancestor', 0, 1) with nowait
create table Athena.concept_ancestor
(
    ancestor_concept_id varchar(8000)null,
    descendant_concept_id varchar(8000)null,
    min_levels_of_separation varchar(8000)null,
    max_levels_of_separation varchar(8000)null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists Athena.source_to_concept_map
raiserror('Created table: Athena.source_to_concept_map', 0, 1) with nowait
create table Athena.source_to_concept_map
(
    source_code varchar(8000)null,
    source_concept_id varchar(8000)null,
    source_vocabulary_id varchar(8000)null,
    source_code_description varchar(8000)null,
    target_concept_id varchar(8000)null,
    target_vocabulary_id varchar(8000)null,
    valid_start_date varchar(8000)null,
    valid_end_date varchar(8000)null,
    invalid_reason varchar(8000)null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists Athena.drug_strength
raiserror('Created table: Athena.drug_strength', 0, 1) with nowait
create table Athena.drug_strength
(
    drug_concept_id varchar(8000)null,
    ingredient_concept_id varchar(8000)null,
    amount_value varchar(8000)null,
    amount_unit_concept_id varchar(8000)null,
    numerator_value varchar(8000)null,
    numerator_unit_concept_id varchar(8000)null,
    denominator_value varchar(8000)null,
    denominator_unit_concept_id varchar(8000)null,
    box_size varchar(8000)null,
    valid_start_date varchar(8000)null,
    valid_end_date varchar(8000)null,
    invalid_reason varchar(8000)null
);
/**************************
Standardized meta-data
***************************/
--HINT DISTRIBUTE ON RANDOM
drop table if exists Athena.cdm_source
raiserror('Created table: Athena.cdm_source', 0, 1) with nowait
create table Athena.cdm_source
(
    cdm_source_name varchar(8000)null,
    cdm_source_abbreviation varchar(8000)null,
    cdm_holder varchar(8000)null,
    source_description varchar(8000)null,
    source_documentation_reference varchar(8000)null,
    cdm_etl_reference varchar(8000)null,
    source_release_date varchar(8000)null,
    cdm_release_date varchar(8000)null,
    cdm_version varchar(8000)null,
    vocabulary_version varchar(8000)null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists Athena.metadata
raiserror('Created table: Athena.metadata', 0, 1) with nowait
create table Athena.metadata
(
    metadata_concept_id varchar(8000)null,
    metadata_type_concept_id varchar(8000)null,
    name varchar(8000)null,
    value_as_string varchar(8000)null,
    value_as_concept_id varchar(8000)null,
    metadata_date varchar(8000)null,
    metadata_datetime varchar(8000)null
);

insert into Athena.metadata
(
    metadata_concept_id,
    metadata_type_concept_id,
    name,
    value_as_string,
    value_as_concept_id,
    metadata_date,
    metadata_datetime
) --Added cdm version record
values
(
    0, 0, 'CDM Version', '6.0', 0, null, null
);
/************************
Standardized clinical data
************************/
--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists Athena.person
raiserror('Created table: Athena.person', 0, 1) with nowait
create table Athena.person
(
    person_id varchar(8000)null,
    gender_concept_id varchar(8000)null,
    year_of_birth varchar(8000)null,
    month_of_birth varchar(8000)null,
    day_of_birth varchar(8000)null,
    birth_datetime varchar(8000)null,
    death_datetime varchar(8000)null,
    race_concept_id varchar(8000)null,
    ethnicity_concept_id varchar(8000)null,
    location_id varchar(8000)null,
    provider_id varchar(8000)null,
    care_site_id varchar(8000)null,
    person_source_value varchar(8000)null,
    gender_source_value varchar(8000)null,
    gender_source_concept_id varchar(8000)null,
    race_source_value varchar(8000)null,
    race_source_concept_id varchar(8000)null,
    ethnicity_source_value varchar(8000)null,
    ethnicity_source_concept_id varchar(8000)null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists Athena.observation_period
raiserror('Created table: Athena.observation_period', 0, 1) with nowait
create table Athena.observation_period
(
    observation_period_id varchar(8000)null,
    person_id varchar(8000)null,
    observation_period_start_date varchar(8000)null,
    observation_period_end_date varchar(8000)null,
    period_type_concept_id varchar(8000)null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists Athena.specimen
raiserror('Created table: Athena.specimen', 0, 1) with nowait
create table Athena.specimen
(
    specimen_id varchar(8000)null,
    person_id varchar(8000)null,
    specimen_concept_id varchar(8000)null,
    specimen_type_concept_id varchar(8000)null,
    specimen_date varchar(8000)null,
    specimen_datetime varchar(8000)null,
    quantity varchar(8000)null,
    unit_concept_id varchar(8000)null,
    anatomic_site_concept_id varchar(8000)null,
    disease_status_concept_id varchar(8000)null,
    specimen_source_id varchar(8000)null,
    specimen_source_value varchar(8000)null,
    unit_source_value varchar(8000)null,
    anatomic_site_source_value varchar(8000)null,
    disease_status_source_value varchar(8000)null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists Athena.visit_occurrence
raiserror('Created table: Athena.visit_occurrence', 0, 1) with nowait
create table Athena.visit_occurrence
(
    visit_occurrence_id varchar(8000)null,
    person_id varchar(8000)null,
    visit_concept_id varchar(8000)null,
    visit_start_date varchar(8000)null,
    visit_start_datetime varchar(8000)null,
    visit_end_date varchar(8000)null,
    visit_end_datetime varchar(8000)null,
    visit_type_concept_id varchar(8000)null,
    provider_id varchar(8000)null,
    care_site_id varchar(8000)null,
    visit_source_value varchar(8000)null,
    visit_source_concept_id varchar(8000)null,
    admitted_from_concept_id varchar(8000)null,
    admitted_from_source_value varchar(8000)null,
    discharge_to_source_value varchar(8000)null,
    discharge_to_concept_id varchar(8000)null,
    preceding_visit_occurrence_id varchar(8000)null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists Athena.visit_detail
raiserror('Created table: Athena.visit_detail', 0, 1) with nowait
create table Athena.visit_detail
(
    visit_detail_id varchar(8000)null,
    person_id varchar(8000)null,
    visit_detail_concept_id varchar(8000)null,
    visit_detail_start_date varchar(8000)null,
    visit_detail_start_datetime varchar(8000)null,
    visit_detail_end_date varchar(8000)null,
    visit_detail_end_datetime varchar(8000)null,
    visit_detail_type_concept_id varchar(8000)null,
    provider_id varchar(8000)null,
    care_site_id varchar(8000)null,
    discharge_to_concept_id varchar(8000)null,
    admitted_from_concept_id varchar(8000)null,
    admitted_from_source_value varchar(8000)null,
    visit_detail_source_value varchar(8000)null,
    visit_detail_source_concept_id varchar(8000)null,
    discharge_to_source_value varchar(8000)null,
    preceding_visit_detail_id varchar(8000)null,
    visit_detail_parent_id varchar(8000)null,
    visit_occurrence_id varchar(8000)null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists Athena.procedure_occurrence
raiserror('Created table: Athena.procedure_occurrence', 0, 1) with nowait
create table Athena.procedure_occurrence
(
    procedure_occurrence_id varchar(8000)null,
    person_id varchar(8000)null,
    procedure_concept_id varchar(8000)null,
    procedure_date varchar(8000)null,
    procedure_datetime varchar(8000)null,
    procedure_type_concept_id varchar(8000)null,
    modifier_concept_id varchar(8000)null,
    quantity varchar(8000)null,
    provider_id varchar(8000)null,
    visit_occurrence_id varchar(8000)null,
    visit_detail_id varchar(8000)null,
    procedure_source_value varchar(8000)null,
    procedure_source_concept_id varchar(8000)null,
    modifier_source_value varchar(8000)null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists Athena.drug_exposure
raiserror('Created table: Athena.drug_exposure', 0, 1) with nowait
create table Athena.drug_exposure
(
    drug_exposure_id varchar(8000)null,
    person_id varchar(8000)null,
    drug_concept_id varchar(8000)null,
    drug_exposure_start_date varchar(8000)null,
    drug_exposure_start_datetime varchar(8000)null,
    drug_exposure_end_date varchar(8000)null,
    drug_exposure_end_datetime varchar(8000)null,
    verbatim_end_date varchar(8000)null,
    drug_type_concept_id varchar(8000)null,
    stop_reason varchar(8000)null,
    refills varchar(8000)null,
    quantity varchar(8000)null,
    days_supply varchar(8000)null,
    sig varchar(8000)null,
    route_concept_id varchar(8000)null,
    lot_number varchar(8000)null,
    provider_id varchar(8000)null,
    visit_occurrence_id varchar(8000)null,
    visit_detail_id varchar(8000)null,
    drug_source_value varchar(8000)null,
    drug_source_concept_id varchar(8000)null,
    route_source_value varchar(8000)null,
    dose_unit_source_value varchar(8000)null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists Athena.device_exposure
raiserror('Created table: Athena.device_exposure', 0, 1) with nowait
create table Athena.device_exposure
(
    device_exposure_id varchar(8000)null,
    person_id varchar(8000)null,
    device_concept_id varchar(8000)null,
    device_exposure_start_date varchar(8000)null,
    device_exposure_start_datetime varchar(8000)null,
    device_exposure_end_date varchar(8000)null,
    device_exposure_end_datetime varchar(8000)null,
    device_type_concept_id varchar(8000)null,
    unique_device_id varchar(8000)null,
    quantity varchar(8000)null,
    provider_id varchar(8000)null,
    visit_occurrence_id varchar(8000)null,
    visit_detail_id varchar(8000)null,
    device_source_value varchar(8000)null,
    device_source_concept_id varchar(8000)null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists Athena.condition_occurrence
raiserror('Created table: Athena.condition_occurrence', 0, 1) with nowait
create table Athena.condition_occurrence
(
    condition_occurrence_id varchar(8000)null,
    person_id varchar(8000)null,
    condition_concept_id varchar(8000)null,
    condition_start_date varchar(8000)null,
    condition_start_datetime varchar(8000)null,
    condition_end_date varchar(8000)null,
    condition_end_datetime varchar(8000)null,
    condition_type_concept_id varchar(8000)null,
    condition_status_concept_id varchar(8000)null,
    stop_reason varchar(8000)null,
    provider_id varchar(8000)null,
    visit_occurrence_id varchar(8000)null,
    visit_detail_id varchar(8000)null,
    condition_source_value varchar(8000)null,
    condition_source_concept_id varchar(8000)null,
    condition_status_source_value varchar(8000)null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists Athena.measurement
raiserror('Created table: Athena.measurement', 0, 1) with nowait
create table Athena.measurement
(
    measurement_id varchar(8000)null,
    person_id varchar(8000)null,
    measurement_concept_id varchar(8000)null,
    measurement_date varchar(8000)null,
    measurement_datetime varchar(8000)null,
    measurement_time varchar(8000)null,
    measurement_type_concept_id varchar(8000)null,
    operator_concept_id varchar(8000)null,
    value_as_number varchar(8000)null,
    value_as_concept_id varchar(8000)null,
    unit_concept_id varchar(8000)null,
    range_low varchar(8000)null,
    range_high varchar(8000)null,
    provider_id varchar(8000)null,
    visit_occurrence_id varchar(8000)null,
    visit_detail_id varchar(8000)null,
    measurement_source_value varchar(8000)null,
    measurement_source_concept_id varchar(8000)null,
    unit_source_value varchar(8000)null,
    value_source_value varchar(8000)null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists Athena.note
raiserror('Created table: Athena.note', 0, 1) with nowait
create table Athena.note
(
    note_id varchar(8000)null,
    person_id varchar(8000)null,
    note_event_id varchar(8000)null,
    note_event_field_concept_id varchar(8000)null,
    note_date varchar(8000)null,
    note_datetime varchar(8000)null,
    note_type_concept_id varchar(8000)null,
    note_class_concept_id varchar(8000)null,
    note_title varchar(8000)null,
    note_text varchar(8000)null,
    encoding_concept_id varchar(8000)null,
    language_concept_id varchar(8000)null,
    provider_id varchar(8000)null,
    visit_occurrence_id varchar(8000)null,
    visit_detail_id varchar(8000)null,
    note_source_value varchar(8000)null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists Athena.note_nlp
raiserror('Created table: Athena.note_nlp', 0, 1) with nowait
create table Athena.note_nlp
(
    note_nlp_id varchar(8000)null,
    note_id varchar(8000)null,
    section_concept_id varchar(8000)null,
    snippet varchar(8000)null,
    "offset" varchar(250) null,
    lexical_variant varchar(8000)null,
    note_nlp_concept_id varchar(8000)null,
    nlp_system varchar(8000)null,
    nlp_date varchar(8000)null,
    nlp_datetime varchar(8000)null,
    term_exists varchar(8000)null,
    term_temporal varchar(8000)null,
    term_modifiers varchar(8000)null,
    note_nlp_source_concept_id varchar(8000)null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists Athena.observation
raiserror('Created table: Athena.observation', 0, 1) with nowait
create table Athena.observation
(
    observation_id varchar(8000)null,
    person_id varchar(8000)null,
    observation_concept_id varchar(8000)null,
    observation_date varchar(8000)null,
    observation_datetime varchar(8000)null,
    observation_type_concept_id varchar(8000)null,
    value_as_number varchar(8000)null,
    value_as_string varchar(8000)null,
    value_as_concept_id varchar(8000)null,
    qualifier_concept_id varchar(8000)null,
    unit_concept_id varchar(8000)null,
    provider_id varchar(8000)null,
    visit_occurrence_id varchar(8000)null,
    visit_detail_id varchar(8000)null,
    observation_source_value varchar(8000)null,
    observation_source_concept_id varchar(8000)null,
    unit_source_value varchar(8000)null,
    qualifier_source_value varchar(8000)null,
    observation_event_id varchar(8000)null,
    obs_event_field_concept_id varchar(8000)null,
    value_as_datetime varchar(8000)null
);

--HINT DISTRIBUTE ON KEY(person_id)
drop table if exists Athena.survey_conduct
raiserror('Created table: Athena.survey_conduct', 0, 1) with nowait
create table Athena.survey_conduct
(
    survey_conduct_id varchar(8000)null,
    person_id varchar(8000)null,
    survey_concept_id varchar(8000)null,
    survey_start_date varchar(8000)null,
    survey_start_datetime varchar(8000)null,
    survey_end_date varchar(8000)null,
    survey_end_datetime varchar(8000)null,
    provider_id varchar(8000)null,
    assisted_concept_id varchar(8000)null,
    respondent_type_concept_id varchar(8000)null,
    timing_concept_id varchar(8000)null,
    collection_method_concept_id varchar(8000)null,
    assisted_source_value varchar(8000)null,
    respondent_type_source_value varchar(8000)null,
    timing_source_value varchar(8000)null,
    collection_method_source_value varchar(8000)null,
    survey_source_value varchar(8000)null,
    survey_source_concept_id varchar(8000)null,
    survey_source_identifier varchar(8000)null,
    validated_survey_concept_id varchar(8000)null,
    validated_survey_source_value varchar(8000)null,
    survey_version_number varchar(8000)null,
    visit_occurrence_id varchar(8000)null,
    visit_detail_id varchar(8000)null,
    response_visit_occurrence_id varchar(8000)null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists Athena.fact_relationship
raiserror('Created table: Athena.fact_relationship', 0, 1) with nowait
create table Athena.fact_relationship
(
    domain_concept_id_1 varchar(8000)null,
    fact_id_1 varchar(8000)null,
    domain_concept_id_2 varchar(8000)null,
    fact_id_2 varchar(8000)null,
    relationship_concept_id varchar(8000)null
);
/************************
Standardized health system data
************************/
--HINT DISTRIBUTE ON RANDOM
drop table if exists Athena.location
raiserror('Created table: Athena.location', 0, 1) with nowait
create table Athena.location
(
    location_id varchar(8000)null,
    address_1 varchar(8000)null,
    address_2 varchar(8000)null,
    city varchar(8000)null,
    state varchar(8000)null,
    zip varchar(8000)null,
    county varchar(8000)null,
    country varchar(8000)null,
    location_source_value varchar(8000)null,
    latitude varchar(8000)null,
    longitude varchar(8000)null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists Athena.location_history
raiserror('Created table: Athena.location_history', 0, 1) with nowait
create table Athena.location_history
(
    location_history_id varchar(8000)null,
    location_id varchar(8000)null,
    relationship_type_concept_id varchar(8000)null,
    domain_id varchar(8000)null,
    entity_id varchar(8000)null,
    start_date varchar(8000)null,
    end_date varchar(8000)null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists Athena.care_site
raiserror('Created table: Athena.care_site', 0, 1) with nowait
create table Athena.care_site
(
    care_site_id varchar(8000)null,
    care_site_name varchar(8000)null,
    place_of_service_concept_id varchar(8000)null,
    location_id varchar(8000)null,
    care_site_source_value varchar(8000)null,
    place_of_service_source_value varchar(8000)null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists Athena.provider
raiserror('Created table: Athena.provider', 0, 1) with nowait
create table Athena.provider
(
    provider_id varchar(8000)null,
    provider_name varchar(8000)null,
    NPI varchar(8000)null,
    DEA varchar(8000)null,
    specialty_concept_id varchar(8000)null,
    care_site_id varchar(8000)null,
    year_of_birth varchar(8000)null,
    gender_concept_id varchar(8000)null,
    provider_source_value varchar(8000)null,
    specialty_source_value varchar(8000)null,
    specialty_source_concept_id varchar(8000)null,
    gender_source_value varchar(8000)null,
    gender_source_concept_id varchar(8000)null
);
/************************
Standardized health economics
************************/
--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists Athena.payer_plan_period
raiserror('Created table: Athena.payer_plan_period', 0, 1) with nowait
create table Athena.payer_plan_period
(
    payer_plan_period_id varchar(8000)null,
    person_id varchar(8000)null,
    contract_person_id varchar(8000)null,
    payer_plan_period_start_date varchar(8000)null,
    payer_plan_period_end_date varchar(8000)null,
    payer_concept_id varchar(8000)null,
    plan_concept_id varchar(8000)null,
    contract_concept_id varchar(8000)null,
    sponsor_concept_id varchar(8000)null,
    stop_reason_concept_id varchar(8000)null,
    payer_source_value varchar(8000)null,
    payer_source_concept_id varchar(8000)null,
    plan_source_value varchar(8000)null,
    plan_source_concept_id varchar(8000)null,
    contract_source_value varchar(8000)null,
    contract_source_concept_id varchar(8000)null,
    sponsor_source_value varchar(8000)null,
    sponsor_source_concept_id varchar(8000)null,
    family_source_value varchar(8000)null,
    stop_reason_source_value varchar(8000)null,
    stop_reason_source_concept_id varchar(8000)null
);

--HINT DISTRIBUTE ON KEY(person_id)
drop table if exists Athena.cost
raiserror('Created table: Athena.cost', 0, 1) with nowait
create table Athena.cost
(
    cost_id varchar(8000)null,
    person_id varchar(8000)null,
    cost_event_id varchar(8000)null,
    cost_event_field_concept_id varchar(8000)null,
    cost_concept_id varchar(8000)null,
    cost_type_concept_id varchar(8000)null,
    currency_concept_id varchar(8000)null,
    cost varchar(8000)null,
    incurred_date varchar(8000)null,
    billed_date varchar(8000)null,
    paid_date varchar(8000)null,
    revenue_code_concept_id varchar(8000)null,
    drg_concept_id varchar(8000)null,
    cost_source_value varchar(8000)null,
    cost_source_concept_id varchar(8000)null,
    revenue_code_source_value varchar(8000)null,
    drg_source_value varchar(8000)null,
    payer_plan_period_id varchar(8000)null
);
/************************
Standardized derived elements
************************/
--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists Athena.drug_era
raiserror('Created table: Athena.drug_era', 0, 1) with nowait
create table Athena.drug_era
(
    drug_era_id varchar(8000)null,
    person_id varchar(8000)null,
    drug_concept_id varchar(8000)null,
    drug_era_start_datetime varchar(8000)null,
    drug_era_end_datetime varchar(8000)null,
    drug_exposure_count varchar(8000)null,
    gap_days varchar(8000)null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists Athena.dose_era
raiserror('Created table: Athena.dose_era', 0, 1) with nowait
create table Athena.dose_era
(
    dose_era_id varchar(8000)null,
    person_id varchar(8000)null,
    drug_concept_id varchar(8000)null,
    unit_concept_id varchar(8000)null,
    dose_value varchar(8000)null,
    dose_era_start_datetime varchar(8000)null,
    dose_era_end_datetime varchar(8000)null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists Athena.condition_era
raiserror('Created table: Athena.condition_era', 0, 1) with nowait
create table Athena.condition_era
(
    condition_era_id varchar(8000)null,
    person_id varchar(8000)null,
    condition_concept_id varchar(8000)null,
    condition_era_start_datetime varchar(8000)null,
    condition_era_end_datetime varchar(8000)null,
    condition_occurrence_count varchar(8000)null
);