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
/*****************************
My Additions:

* Added DB creation statement
* Formatted the results 
* Added drop if exist statements
* Widening code name fields to accomodate larger data
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
GO
/************************
Standardized vocabulary
************************/
--HINT DISTRIBUTE ON RANDOM
drop table if exists dbo.concept
raiserror('Created table: dbo.concept', 0, 1) with nowait
create table dbo.concept
(
    concept_id integer not null,
    concept_name varchar(2000) not null,
    domain_id varchar(20) not null,
    vocabulary_id varchar(20) not null,
    concept_class_id varchar(20) not null,
    standard_concept varchar(1) null,
    concept_code varchar(50) not null,
    valid_start_date date not null,
    valid_end_date date not null,
    invalid_reason varchar(1) null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists dbo.vocabulary
raiserror('Created table: dbo.vocabulary', 0, 1) with nowait
create table dbo.vocabulary
(
    vocabulary_id varchar(20) not null,
    vocabulary_name varchar(2000) not null,
    vocabulary_reference varchar(2000) not null,
    vocabulary_version varchar(2000) null,
    vocabulary_concept_id integer not null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists dbo.domain
raiserror('Created table: dbo.domain', 0, 1) with nowait
create table dbo.domain
(
    domain_id varchar(20) not null,
    domain_name varchar(2000) not null,
    domain_concept_id integer not null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists dbo.concept_class
raiserror('Created table: dbo.concept_class', 0, 1) with nowait
create table dbo.concept_class
(
    concept_class_id varchar(20) not null,
    concept_class_name varchar(2000) not null,
    concept_class_concept_id integer not null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists dbo.concept_relationship
raiserror('Created table: dbo.concept_relationship', 0, 1) with nowait
create table dbo.concept_relationship
(
    concept_id_1 integer not null,
    concept_id_2 integer not null,
    relationship_id varchar(20) not null,
    valid_start_date date not null,
    valid_end_date date not null,
    invalid_reason varchar(1) null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists dbo.relationship
raiserror('Created table: dbo.relationship', 0, 1) with nowait
create table dbo.relationship
(
    relationship_id varchar(20) not null,
    relationship_name varchar(2000) not null,
    is_hierarchical varchar(1) not null,
    defines_ancestry varchar(1) not null,
    reverse_relationship_id varchar(20) not null,
    relationship_concept_id integer not null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists dbo.concept_synonym
raiserror('Created table: dbo.concept_synonym', 0, 1) with nowait
create table dbo.concept_synonym
(
    concept_id integer not null,
    concept_synonym_name varchar(2000) not null,
    language_concept_id integer not null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists dbo.concept_ancestor
raiserror('Created table: dbo.concept_ancestor', 0, 1) with nowait
create table dbo.concept_ancestor
(
    ancestor_concept_id integer not null,
    descendant_concept_id integer not null,
    min_levels_of_separation integer not null,
    max_levels_of_separation integer not null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists dbo.source_to_concept_map
raiserror('Created table: dbo.source_to_concept_map', 0, 1) with nowait
create table dbo.source_to_concept_map
(
    source_code varchar(50) not null,
    source_concept_id integer not null,
    source_vocabulary_id varchar(20) not null,
    source_code_description varchar(2000) null,
    target_concept_id integer not null,
    target_vocabulary_id varchar(20) not null,
    valid_start_date date not null,
    valid_end_date date not null,
    invalid_reason varchar(1) null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists dbo.drug_strength
raiserror('Created table: dbo.drug_strength', 0, 1) with nowait
create table dbo.drug_strength
(
    drug_concept_id integer not null,
    ingredient_concept_id integer not null,
    amount_value float null,
    amount_unit_concept_id integer null,
    numerator_value float null,
    numerator_unit_concept_id integer null,
    denominator_value float null,
    denominator_unit_concept_id integer null,
    box_size integer null,
    valid_start_date date not null,
    valid_end_date date not null,
    invalid_reason varchar(1) null
);
/**************************
Standardized meta-data
***************************/
--HINT DISTRIBUTE ON RANDOM
drop table if exists dbo.cdm_source
raiserror('Created table: dbo.cdm_source', 0, 1) with nowait
create table dbo.cdm_source
(
    cdm_source_name varchar(2000) not null,
    cdm_source_abbreviation varchar(25) null,
    cdm_holder varchar(2000) null,
    source_description varchar(max) null,
    source_documentation_reference varchar(2000) null,
    cdm_etl_reference varchar(2000) null,
    source_release_date date null,
    cdm_release_date date null,
    cdm_version varchar(10) null,
    vocabulary_version varchar(20) null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists dbo.metadata
raiserror('Created table: dbo.metadata', 0, 1) with nowait
create table dbo.metadata
(
    metadata_concept_id integer not null,
    metadata_type_concept_id integer not null,
    name varchar(250) not null,
    value_as_string varchar(max) null,
    value_as_concept_id integer null,
    metadata_date date null,
    metadata_datetime datetime2 null
);

insert into dbo.metadata
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
drop table if exists dbo.person
raiserror('Created table: dbo.person', 0, 1) with nowait
create table dbo.person
(
    person_id bigint not null,
    gender_concept_id integer not null,
    year_of_birth integer not null,
    month_of_birth integer null,
    day_of_birth integer null,
    birth_datetime datetime2 null,
    death_datetime datetime2 null,
    race_concept_id integer not null,
    ethnicity_concept_id integer not null,
    location_id bigint null,
    provider_id bigint null,
    care_site_id bigint null,
    person_source_value varchar(50) null,
    gender_source_value varchar(50) null,
    gender_source_concept_id integer not null,
    race_source_value varchar(50) null,
    race_source_concept_id integer not null,
    ethnicity_source_value varchar(50) null,
    ethnicity_source_concept_id integer not null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists dbo.observation_period
raiserror('Created table: dbo.observation_period', 0, 1) with nowait
create table dbo.observation_period
(
    observation_period_id bigint not null,
    person_id bigint not null,
    observation_period_start_date date not null,
    observation_period_end_date date not null,
    period_type_concept_id integer not null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists dbo.specimen
raiserror('Created table: dbo.specimen', 0, 1) with nowait
create table dbo.specimen
(
    specimen_id bigint not null,
    person_id bigint not null,
    specimen_concept_id integer not null,
    specimen_type_concept_id integer not null,
    specimen_date date null,
    specimen_datetime datetime2 not null,
    quantity float null,
    unit_concept_id integer null,
    anatomic_site_concept_id integer not null,
    disease_status_concept_id integer not null,
    specimen_source_id varchar(50) null,
    specimen_source_value varchar(50) null,
    unit_source_value varchar(50) null,
    anatomic_site_source_value varchar(50) null,
    disease_status_source_value varchar(50) null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists dbo.visit_occurrence
raiserror('Created table: dbo.visit_occurrence', 0, 1) with nowait
create table dbo.visit_occurrence
(
    visit_occurrence_id bigint not null,
    person_id bigint not null,
    visit_concept_id integer not null,
    visit_start_date date null,
    visit_start_datetime datetime2 not null,
    visit_end_date date null,
    visit_end_datetime datetime2 not null,
    visit_type_concept_id integer not null,
    provider_id bigint null,
    care_site_id bigint null,
    visit_source_value varchar(50) null,
    visit_source_concept_id integer not null,
    admitted_from_concept_id integer not null,
    admitted_from_source_value varchar(50) null,
    discharge_to_source_value varchar(50) null,
    discharge_to_concept_id integer not null,
    preceding_visit_occurrence_id bigint null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists dbo.visit_detail
raiserror('Created table: dbo.visit_detail', 0, 1) with nowait
create table dbo.visit_detail
(
    visit_detail_id bigint not null,
    person_id bigint not null,
    visit_detail_concept_id integer not null,
    visit_detail_start_date date null,
    visit_detail_start_datetime datetime2 not null,
    visit_detail_end_date date null,
    visit_detail_end_datetime datetime2 not null,
    visit_detail_type_concept_id integer not null,
    provider_id bigint null,
    care_site_id bigint null,
    discharge_to_concept_id integer not null,
    admitted_from_concept_id integer not null,
    admitted_from_source_value varchar(50) null,
    visit_detail_source_value varchar(50) null,
    visit_detail_source_concept_id integer not null,
    discharge_to_source_value varchar(50) null,
    preceding_visit_detail_id bigint null,
    visit_detail_parent_id bigint null,
    visit_occurrence_id bigint not null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists dbo.procedure_occurrence
raiserror('Created table: dbo.procedure_occurrence', 0, 1) with nowait
create table dbo.procedure_occurrence
(
    procedure_occurrence_id bigint not null,
    person_id bigint not null,
    procedure_concept_id integer not null,
    procedure_date date null,
    procedure_datetime datetime2 not null,
    procedure_type_concept_id integer not null,
    modifier_concept_id integer not null,
    quantity integer null,
    provider_id bigint null,
    visit_occurrence_id bigint null,
    visit_detail_id bigint null,
    procedure_source_value varchar(50) null,
    procedure_source_concept_id integer not null,
    modifier_source_value varchar(50) null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists dbo.drug_exposure
raiserror('Created table: dbo.drug_exposure', 0, 1) with nowait
create table dbo.drug_exposure
(
    drug_exposure_id bigint not null,
    person_id bigint not null,
    drug_concept_id integer not null,
    drug_exposure_start_date date null,
    drug_exposure_start_datetime datetime2 not null,
    drug_exposure_end_date date null,
    drug_exposure_end_datetime datetime2 not null,
    verbatim_end_date date null,
    drug_type_concept_id integer not null,
    stop_reason varchar(20) null,
    refills integer null,
    quantity float null,
    days_supply integer null,
    sig varchar(max) null,
    route_concept_id integer not null,
    lot_number varchar(50) null,
    provider_id bigint null,
    visit_occurrence_id bigint null,
    visit_detail_id bigint null,
    drug_source_value varchar(50) null,
    drug_source_concept_id integer not null,
    route_source_value varchar(50) null,
    dose_unit_source_value varchar(50) null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists dbo.device_exposure
raiserror('Created table: dbo.device_exposure', 0, 1) with nowait
create table dbo.device_exposure
(
    device_exposure_id bigint not null,
    person_id bigint not null,
    device_concept_id integer not null,
    device_exposure_start_date date null,
    device_exposure_start_datetime datetime2 not null,
    device_exposure_end_date date null,
    device_exposure_end_datetime datetime2 null,
    device_type_concept_id integer not null,
    unique_device_id varchar(50) null,
    quantity integer null,
    provider_id bigint null,
    visit_occurrence_id bigint null,
    visit_detail_id bigint null,
    device_source_value varchar(100) null,
    device_source_concept_id integer not null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists dbo.condition_occurrence
raiserror('Created table: dbo.condition_occurrence', 0, 1) with nowait
create table dbo.condition_occurrence
(
    condition_occurrence_id bigint not null,
    person_id bigint not null,
    condition_concept_id integer not null,
    condition_start_date date null,
    condition_start_datetime datetime2 not null,
    condition_end_date date null,
    condition_end_datetime datetime2 null,
    condition_type_concept_id integer not null,
    condition_status_concept_id integer not null,
    stop_reason varchar(20) null,
    provider_id bigint null,
    visit_occurrence_id bigint null,
    visit_detail_id bigint null,
    condition_source_value varchar(50) null,
    condition_source_concept_id integer not null,
    condition_status_source_value varchar(50) null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists dbo.measurement
raiserror('Created table: dbo.measurement', 0, 1) with nowait
create table dbo.measurement
(
    measurement_id bigint not null,
    person_id bigint not null,
    measurement_concept_id integer not null,
    measurement_date date null,
    measurement_datetime datetime2 not null,
    measurement_time varchar(10) null,
    measurement_type_concept_id integer not null,
    operator_concept_id integer null,
    value_as_number float null,
    value_as_concept_id integer null,
    unit_concept_id integer null,
    range_low float null,
    range_high float null,
    provider_id bigint null,
    visit_occurrence_id bigint null,
    visit_detail_id bigint null,
    measurement_source_value varchar(50) null,
    measurement_source_concept_id integer not null,
    unit_source_value varchar(50) null,
    value_source_value varchar(50) null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists dbo.note
raiserror('Created table: dbo.note', 0, 1) with nowait
create table dbo.note
(
    note_id bigint not null,
    person_id bigint not null,
    note_event_id bigint null,
    note_event_field_concept_id integer not null,
    note_date date null,
    note_datetime datetime2 not null,
    note_type_concept_id integer not null,
    note_class_concept_id integer not null,
    note_title varchar(250) null,
    note_text varchar(max) null,
    encoding_concept_id integer not null,
    language_concept_id integer not null,
    provider_id bigint null,
    visit_occurrence_id bigint null,
    visit_detail_id bigint null,
    note_source_value varchar(50) null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists dbo.note_nlp
raiserror('Created table: dbo.note_nlp', 0, 1) with nowait
create table dbo.note_nlp
(
    note_nlp_id bigint not null,
    note_id bigint not null,
    section_concept_id integer not null,
    snippet varchar(250) null,
    "offset" varchar(250) null,
    lexical_variant varchar(250) not null,
    note_nlp_concept_id integer not null,
    nlp_system varchar(250) null,
    nlp_date date not null,
    nlp_datetime datetime2 null,
    term_exists varchar(1) null,
    term_temporal varchar(50) null,
    term_modifiers varchar(2000) null,
    note_nlp_source_concept_id integer not null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists dbo.observation
raiserror('Created table: dbo.observation', 0, 1) with nowait
create table dbo.observation
(
    observation_id bigint not null,
    person_id bigint not null,
    observation_concept_id integer not null,
    observation_date date null,
    observation_datetime datetime2 not null,
    observation_type_concept_id integer not null,
    value_as_number float null,
    value_as_string varchar(60) null,
    value_as_concept_id integer null,
    qualifier_concept_id integer null,
    unit_concept_id integer null,
    provider_id integer null,
    visit_occurrence_id bigint null,
    visit_detail_id bigint null,
    observation_source_value varchar(50) null,
    observation_source_concept_id integer not null,
    unit_source_value varchar(50) null,
    qualifier_source_value varchar(50) null,
    observation_event_id bigint null,
    obs_event_field_concept_id integer not null,
    value_as_datetime datetime2 null
);

--HINT DISTRIBUTE ON KEY(person_id)
drop table if exists dbo.survey_conduct
raiserror('Created table: dbo.survey_conduct', 0, 1) with nowait
create table dbo.survey_conduct
(
    survey_conduct_id bigint not null,
    person_id bigint not null,
    survey_concept_id integer not null,
    survey_start_date date null,
    survey_start_datetime datetime2 null,
    survey_end_date date null,
    survey_end_datetime datetime2 not null,
    provider_id bigint null,
    assisted_concept_id integer not null,
    respondent_type_concept_id integer not null,
    timing_concept_id integer not null,
    collection_method_concept_id integer not null,
    assisted_source_value varchar(50) null,
    respondent_type_source_value varchar(100) null,
    timing_source_value varchar(100) null,
    collection_method_source_value varchar(100) null,
    survey_source_value varchar(100) null,
    survey_source_concept_id integer not null,
    survey_source_identifier varchar(100) null,
    validated_survey_concept_id integer not null,
    validated_survey_source_value varchar(100) null,
    survey_version_number varchar(20) null,
    visit_occurrence_id bigint null,
    visit_detail_id bigint null,
    response_visit_occurrence_id bigint null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists dbo.fact_relationship
raiserror('Created table: dbo.fact_relationship', 0, 1) with nowait
create table dbo.fact_relationship
(
    domain_concept_id_1 integer not null,
    fact_id_1 bigint not null,
    domain_concept_id_2 integer not null,
    fact_id_2 bigint not null,
    relationship_concept_id integer not null
);
/************************
Standardized health system data
************************/
--HINT DISTRIBUTE ON RANDOM
drop table if exists dbo.location
raiserror('Created table: dbo.location', 0, 1) with nowait
create table dbo.location
(
    location_id bigint not null,
    address_1 varchar(50) null,
    address_2 varchar(50) null,
    city varchar(50) null,
    state varchar(2) null,
    zip varchar(9) null,
    county varchar(20) null,
    country varchar(100) null,
    location_source_value varchar(50) null,
    latitude float null,
    longitude float null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists dbo.location_history
raiserror('Created table: dbo.location_history', 0, 1) with nowait
create table dbo.location_history
(
    location_history_id bigint not null,
    location_id bigint not null,
    relationship_type_concept_id integer not null,
    domain_id varchar(50) not null,
    entity_id bigint not null,
    start_date date not null,
    end_date date null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists dbo.care_site
raiserror('Created table: dbo.care_site', 0, 1) with nowait
create table dbo.care_site
(
    care_site_id bigint not null,
    care_site_name varchar(2000) null,
    place_of_service_concept_id integer not null,
    location_id bigint null,
    care_site_source_value varchar(50) null,
    place_of_service_source_value varchar(50) null
);

--HINT DISTRIBUTE ON RANDOM
drop table if exists dbo.provider
raiserror('Created table: dbo.provider', 0, 1) with nowait
create table dbo.provider
(
    provider_id bigint not null,
    provider_name varchar(2000) null,
    NPI varchar(20) null,
    DEA varchar(20) null,
    specialty_concept_id integer not null,
    care_site_id bigint null,
    year_of_birth integer null,
    gender_concept_id integer not null,
    provider_source_value varchar(50) null,
    specialty_source_value varchar(50) null,
    specialty_source_concept_id integer not null,
    gender_source_value varchar(50) null,
    gender_source_concept_id integer not null
);
/************************
Standardized health economics
************************/
--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists dbo.payer_plan_period
raiserror('Created table: dbo.payer_plan_period', 0, 1) with nowait
create table dbo.payer_plan_period
(
    payer_plan_period_id bigint not null,
    person_id bigint not null,
    contract_person_id bigint null,
    payer_plan_period_start_date date not null,
    payer_plan_period_end_date date not null,
    payer_concept_id integer not null,
    plan_concept_id integer not null,
    contract_concept_id integer not null,
    sponsor_concept_id integer not null,
    stop_reason_concept_id integer not null,
    payer_source_value varchar(50) null,
    payer_source_concept_id integer not null,
    plan_source_value varchar(50) null,
    plan_source_concept_id integer not null,
    contract_source_value varchar(50) null,
    contract_source_concept_id integer not null,
    sponsor_source_value varchar(50) null,
    sponsor_source_concept_id integer not null,
    family_source_value varchar(50) null,
    stop_reason_source_value varchar(50) null,
    stop_reason_source_concept_id integer not null
);

--HINT DISTRIBUTE ON KEY(person_id)
drop table if exists dbo.cost
raiserror('Created table: dbo.cost', 0, 1) with nowait
create table dbo.cost
(
    cost_id bigint not null,
    person_id bigint not null,
    cost_event_id bigint not null,
    cost_event_field_concept_id integer not null,
    cost_concept_id integer not null,
    cost_type_concept_id integer not null,
    currency_concept_id integer not null,
    cost float null,
    incurred_date date not null,
    billed_date date null,
    paid_date date null,
    revenue_code_concept_id integer not null,
    drg_concept_id integer not null,
    cost_source_value varchar(50) null,
    cost_source_concept_id integer not null,
    revenue_code_source_value varchar(50) null,
    drg_source_value varchar(3) null,
    payer_plan_period_id bigint null
);
/************************
Standardized derived elements
************************/
--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists dbo.drug_era
raiserror('Created table: dbo.drug_era', 0, 1) with nowait
create table dbo.drug_era
(
    drug_era_id bigint not null,
    person_id bigint not null,
    drug_concept_id integer not null,
    drug_era_start_datetime datetime2 not null,
    drug_era_end_datetime datetime2 not null,
    drug_exposure_count integer null,
    gap_days integer null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists dbo.dose_era
raiserror('Created table: dbo.dose_era', 0, 1) with nowait
create table dbo.dose_era
(
    dose_era_id bigint not null,
    person_id bigint not null,
    drug_concept_id integer not null,
    unit_concept_id integer not null,
    dose_value float not null,
    dose_era_start_datetime datetime2 not null,
    dose_era_end_datetime datetime2 not null
);

--HINT DISTRIBUTE_ON_KEY(person_id)
drop table if exists dbo.condition_era
raiserror('Created table: dbo.condition_era', 0, 1) with nowait
create table dbo.condition_era
(
    condition_era_id bigint not null,
    person_id bigint not null,
    condition_concept_id integer not null,
    condition_era_start_datetime datetime2 not null,
    condition_era_end_datetime datetime2 not null,
    condition_occurrence_count integer null
);