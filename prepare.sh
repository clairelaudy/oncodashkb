#!/usr/bin/env bash

if [[ -z "$1" ]] ; then
    echo "ERROR, usage: $0 <DECIDER_data_version>" >&2
    exit 2
fi

set -eu
set -o pipefail

data_dir="data"
data_version="$1"

script_dir="$(dirname $0)"


echo "# Check for neo4j.pass..." >&2
if [[ ! -f neo4j.pass ]] ; then
    echo "File: neo4j.pass is missing." >&2
    exit 1
fi
echo "neo4j — OK" >&2


echo "# Check dependencies..." >&2
REQUIRED_CMD="gzip"
for p in $REQUIRED_CMD ; do
    if ! command -v $p > /dev/null ; then
        echo "Package '$p' is missing, please install it." >&2
        exit 1
    fi
done


if [[ -d $script_dir/.venv ]] ; then
    echo "Environment already existing, if you want to upgrade it, either:" >&2
    echo "  * remove the '.venv' directory and run 'prepare.sh' again," >&2
    echo "  * or run 'uv sync' manually." >&2
else
    echo "Install environment..." >&2
    uv sync --no-upgrade
    echo "Sync — OK" >&2
fi


echo "# Download data:" >&2
mkdir -p data
cd data

echo "## Gene Ontology..." >&2
mkdir -p GO
cd GO
wget --no-clobber https://current.geneontology.org/annotations/goa_human.gaf.gz
# gunzip goa_human.gaf.gz
wget --no-clobber https://purl.obolibrary.org/obo/go.owl
cd ..
echo "## GO — OK" >&2


echo " | Open Targets..." >&2
rsync_cmd="rsync --ignore-existing -rpltvz --delete"
ot_version="25.12"
mkdir -p OT
cd OT
echo " | | Target..." >&2
$rsync_cmd rsync.ebi.ac.uk::pub/databases/opentargets/platform/${ot_version}/output/target .

echo " | | Drug-Mechanism..." >&2
$rsync_cmd rsync.ebi.ac.uk::pub/databases/opentargets/platform/${ot_version}/output/drug_mechanism_of_action .

echo " | | Drug-Molecule..." >&2
$rsync_cmd rsync.ebi.ac.uk::pub/databases/opentargets/platform/${ot_version}/output/drug_molecule .

echo " | OK" >&2


echo " | OmniPath Networks..." >&2
mkdir -p omnipath_networks
cd omnipath_networks
wget https://archive.omnipathdb.org/omnipath_webservice_interactions__latest.tsv.gz
cd ..
echo " | OmniPath Networks — OK" >&2


echo " | Gene Symbol to Ensembl ID" >&2
mkdir -p HGNC
cd HGNC
wget https://storage.googleapis.com/public-download-files/hgnc/tsv/tsv/hgnc_complete_set.txt
cd ..
echo " | Gene Symbol to Ensemble ID dataframe — OK" >&2


echo "# Check DECIDER data..." >&2
check() {
    if [[ ! -f "$data_dir/DECIDER/$data_version/$1" ]] ; then
        echo "File: $data_dir/DECIDER/$data_version/$1 is missing." >&2
        exit 1
    fi
}

if [[ -d $data_dir/DECIDER ]] ; then
    cd DECIDER
    # check genomics_oncokbannotation.csv
    # check genomics_cgimutation.csv
    # check genomics_cgidrugprescriptions.csv
    # check genomics_cgicopynumberalteration.csv
    # check clin_overview_clinicaldata.csv
    # check ../../oncodashkb/adapters/Hugo_Symbol_genes.conf
    # check treatments.csv
    # check snv_annotated.csv
    # check OncoKB_gene_symbols.conf
    # check cna_annotated.csv
    check clinical_export.csv
    check snv_local.csv
    check snv_external.csv
    check cna_local.csv
    check cna_external.csv
    cd ..
else
    echo "The $data_dir/DECIDER directory is missing." >&2
    exit 1
fi
# cp -a ../oncodashkb/adapters/Hugo_Symbol_genes.conf .
echo "DECIDER — OK" >&2

echo "Downloading OmniPath mapping files and custom transformers" >&2
cd ..
cd oncodashkb
mkdir transformers
cd transformers
wget -L https://raw.githubusercontent.com/njmmatthieu/omnipath-secondary-adapter/refs/heads/directed/src/omnipath_secondary_adapter/transformers/networks.py -O networks.py
echo "OmniPath Networks custom transformer saved." >&2
cd ..
cd adapters
wget -L https://raw.githubusercontent.com/njmmatthieu/omnipath-secondary-adapter/refs/heads/directed/src/omnipath_secondary_adapter/adapters/networks.yaml -O omnipath_networks.yaml
echo "OmniPath Networks mapping file saved." >&2
cd ../..

echo "Downloading OpenTargets mapping files and custom transformers" >&2
cd ..
cd oncodashkb
cd transformers
wget -L https://raw.githubusercontent.com/njmmatthieu/opentargets-dti/refs/heads/for_oncodashkb/adapters/ot-transformers.py -O ot_transformers.py
echo "Open Targets custom transformers saved." >&2
cd ..
cd adapters
wget -L raw.githubusercontent.com/njmmatthieu/opentargets-dti/refs/heads/for_oncodashkb/adapters/target.yaml -O ot_target.yaml
echo "Open Targets targets mapping file saved." >&2
wget -L https://raw.githubusercontent.com/njmmatthieu/opentargets-dti/refs/heads/for_oncodashkb/adapters/drug_mechanism_of_action.yaml -O ot_drug_mechanism_of_action.yaml
echo "Open Targets mechanisms of action mapping file saved." >&2
wget -L https://raw.githubusercontent.com/njmmatthieu/opentargets-dti/refs/heads/for_oncodashkb/adapters/drug_molecule.yaml -O ot_drug_molecule.yaml
echo "Open Targets Drug mapping file saved." >&2
cd ../..

echo "Downloading OpenTargets mapping files and custom transformers" >&2
cd ..
cd oncodashkb
cd transformers
wget -L https://raw.githubusercontent.com/njmmatthieu/opentargets-dti/refs/heads/for_oncodashkb/adapters/ot-transformers.py -O ot_transformers.py
echo "Open Targets custom transformers saved." >&2
cd ..
cd adapters
wget -L raw.githubusercontent.com/njmmatthieu/opentargets-dti/refs/heads/for_oncodashkb/adapters/target.yaml -O ot_target.yaml
echo "Open Targets targets mapping file saved." >&2
wget -L https://raw.githubusercontent.com/njmmatthieu/opentargets-dti/refs/heads/for_oncodashkb/adapters/drug_mechanism_of_action.yaml -O ot_drug_mechanism_of_action.yaml
echo "Open Targets mechanisms of action mapping file saved." >&2
wget -L https://raw.githubusercontent.com/njmmatthieu/opentargets-dti/refs/heads/for_oncodashkb/adapters/drug_molecule.yaml -O ot_drug_molecule.yaml
echo "Open Targets Drug mapping file saved." >&2
cd ../..


echo "Everything is OK, you can now call: ./make.sh." >&2
