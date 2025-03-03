#!/bin/bash

ROOT_RUN_DIR="/usr/src/app/"
ROOT_DIR=`dirname $0`/..
DAX_GEN_DIR="${ROOT_DIR}/dax-generator-3"

COMPILE_CMD="javac -classpath .:${DAX_GEN_DIR}:${DAX_GEN_DIR}/lib/jackson-core-2.9.10.jar:${DAX_GEN_DIR}/lib/org.everit.json.schema-1.12.0.jar:${DAX_GEN_DIR}/org/scec/cme/cybershake/dax3:${DAX_GEN_DIR}/lib/mysql-connector-java-5.0.5-bin.jar:${DAX_GEN_DIR}/lib/pegasus.jar:${DAX_GEN_DIR}/lib/globus_rls_client.jar:${DAX_GEN_DIR}/lib/commons-cli-1.1.jar:${DAX_GEN_DIR}/lib/opensha-cybershake-all.jar ${DAX_GEN_DIR}/org/scec/cme/cybershake/dax3/CyberShake_PP_DAXGen.java ${DAX_GEN_DIR}/org/scec/cme/cybershake/dax3/CyberShake_DB_DAXGen.java ${DAX_GEN_DIR}/org/scec/cme/cybershake/dax3/DBConnect.java ${DAX_GEN_DIR}/org/scec/cme/cybershake/dax3/PP_DAXParameters.java ${DAX_GEN_DIR}/org/scec/cme/cybershake/dax3/RunIDQuery.java ${DAX_GEN_DIR}/org/scec/cme/cybershake/dax3/RuptureVariationDB.java"

RUN_CMD="java -classpath .:${DAX_GEN_DIR}:${DAX_GEN_DIR}/lib/snakeyaml-1.25.jar:${DAX_GEN_DIR}/lib/jackson-coreutils-1.8.jar:${DAX_GEN_DIR}/lib/jackson-annotations-2.9.10.jar:${DAX_GEN_DIR}/lib/mysql-connector-java-5.0.5-bin.jar:${DAX_GEN_DIR}/lib/pegasus.jar:${DAX_GEN_DIR}/lib/jackson-databind-2.9.10.jar:${DAX_GEN_DIR}/lib/jackson-dataformat-yaml-2.9.10.jar:${DAX_GEN_DIR}/lib/jackson-core-2.9.10.jar:${DAX_GEN_DIR}/lib/globus_rls_client.jar:${DAX_GEN_DIR}/lib/commons-cli-1.1.jar:${DAX_GEN_DIR}/lib/opensha-cybershake-all.jar org/scec/cme/cybershake/dax3/CyberShake_PP_DAXGen"

show_help() {
	$COMPILE_CMD
	JAVA_OUT=`$RUN_CMD -h`
	cat << EOF
	Usage: $0 [-h] <-v VELOCITY MODEL> <-e ERF_ID> <-r RV_ID> <-g SGT_ID> <-f FREQ> <-s SITE> [-q SRC_FREQ] [--ppargs DAX generator args]
		-h                      display this help and exit
                -v VELOCITY_MODEL       select velocity model, one of v4 (CVM-S4), vh (CVM-H), vsi (CVM-S4.26), vs1 (SCEC 1D model), vhng (CVM-H, no GTL), or vbbp (BBP 1D model).
                -e ERF_ID               ERF ID
                -r RUP_VAR_ID           Rupture Variation ID
                -g SGT_ID               SGT ID
                -f FREQ                 Simulation frequency (0.5 or 1.0 supported)
                -s SITE                 Site short name
                -q SRC_FREQ             Optional: SGT source filter frequency

	Can be followed by optional PP arguments:
	${JAVA_OUT}
EOF
}

if [ $# -lt 1 ]; then
	show_help
	exit 0
fi

getopts_args=""
for i in $@; do
        if [ "$i" == "--ppargs" ]; then
                break
        else
                getopts_args="$getopts_args $i"
        fi
done
echo $getopts_args

OPTIND=1
VEL_STR=""
ERF=""
RUP_VAR=""
SGT_VAR=""
FREQ=""
SRC_FREQ=""
SITE=""
while getopts ":hv:e:r:g:f:q:s:" opt $getopts_args; do
        case $opt in
                h)      show_help
                        exit 0
                        ;;
                v)      VEL_STR=$OPTARG
                        ;;
                e)      ERF=$OPTARG
                        ;;
                r)      RUP_VAR=$OPTARG
                        ;;
                g)      SGT_VAR=$OPTARG
                        ;;
                f)      FREQ=$OPTARG
                        if [ "$SRC_FREQ" == "" ]; then
                                SRC_FREQ=$FREQ
                        fi
                        ;;
                q)      SRC_FREQ=$OPTARG
                        ;;
                s)      SITE=$OPTARG
                        ;;
                *)      break
        esac
done
shift "$((OPTIND))"

if [ "$VEL_STR" == "" ]; then
        echo "Must specify velocity model."
        exit 1
fi
if [ "$ERF" == "" ]; then
        echo "Must specify ERF ID."
        exit 1
fi
if [ "$RUP_VAR" == "" ]; then
        echo "Must specify rupture variation ID."
        exit 1
fi
if [ "$SGT_VAR" == "" ]; then
        echo "Must specify SGT variation ID."
        exit 1
fi
if [ "$FREQ" == "" ]; then
        echo "Must specify frequency."
        exit 1
fi
if [ "$SITE" == "" ]; then
        echo "Must specify site."
        exit 1
fi


#SITE=$1
#VEL=$2
VEL_ID=0
#ERF=$3
#RUP_VAR=$4
#SGT_VAR=$5
#FREQ=0.5

#shift 5
OPT_ARGS=$@

if [ "$VEL_STR" == "v4" ]; then
	VEL_ID=1
elif [ "$VEL_STR" == "vh" ]; then
	#4 for 11.9
	VEL_ID=4
elif [ "$VEL_STR" == "vhs" ]; then
	VEL_ID=3
elif [ "$VEL_STR" == "vsi" ]; then
	VEL_ID=5
elif [ "$VEL_STR" == "vs1" ]; then
	VEL_ID=6
elif [ "$VEL_STR" == "vhng" ]; then
	VEL_ID=7
elif [ "$VEL_STR" == "vbbp" ]; then
	VEL_ID=8
elif [ $VEL_STR == "vcca1d" ]; then
        #CCA 1D model
        VEL_ID="9"
elif [ $VEL_STR == "vcca" ]; then
        #CCA-06 3D model
        VEL_ID="10"
elif [ $VEL_STR == "v188" ]; then
        #Study 18.8 model
        #CCA-06, USGS Bay Area, CVM-S4.26.M01
        VEL_ID="12"
elif [ $VEL_STR == "vtaper" ]; then
    #Study 22.12 model
    #CVM-S4.26.M01 merged with Ely taper
    VEL_ID="13"
elif [ $VEL_STR == "vsfcvm" ]; then
        VEL_ID="14"
elif [ $VEL_STR == "v246" ]; then
        #Study 24.6 model
        #SFCVM with gabbro mods, CCA-06+taper, NC1D+taper
        VEL_ID="15"
else
	echo "Velocity option $VEL_STR needs to be one of v4, vh, vhs, vsi, vs1, vhng, or vbbp."
	exit 1
fi


#if [ $# -ge 6 ]; then
#    NUM_DAX=$6
#else
#    NUM_DAX=80
#    echo "Defaulting to ${NUM_DAX} DAXs"
#fi

#PRIORITY=""
#if [ $# -eq 7 ]; then
#    PRIORITY=$7
#fi

mkdir ${SITE}_PP_dax

# Get best-match runid from DB
RUN_FILE=${SITE}_PP_dax/run_table.txt
RUN_ID_STRING=""
if [ ! -e ${RUN_FILE} ]; then
    echo "find_run.py ${SITE} ${ERF} ${SGT_VAR} ${RUP_VAR} ${VEL_ID} ${FREQ} ${SRC_FREQ}"
    RUN_ID=`${ROOT_RUN_DIR}/cybershake-tools/runmanager/find_run.py ${SITE} ${ERF} ${SGT_VAR} ${RUP_VAR} ${VEL_ID} ${FREQ} ${SRC_FREQ}`
    if [ $? -ne 0 ]; then
	echo "Failed to find matching run."
	exit 1
    fi
    echo "${RUN_ID} ${SITE} ${ERF} ${SGT_VAR} ${RUP_VAR} ${VEL_ID} ${FREQ} ${SRC_FREQ}" >> ${RUN_FILE}
    #RUN_ID_STRING=${RUN_ID}
else
    # Verify existing IDs are valid
    echo "Using existing run_ids from ${RUN_FILE}"
    FOUND=0

    while read LINE ; do
        RUN_ID=`echo $LINE | awk '{print $1}'`
        SITE_NAME=`echo $LINE | awk '{print $2}'`
	RF_ERF_ID=`echo $LINE | awk '{print $3}'`
	RF_SGT_VAR=`echo $LINE | awk '{print $4}'`
	RF_RUP_VAR=`echo $LINE | awk '{print $5}'`
	RF_VEL_ID=`echo $LINE | awk '{print $6}'`
	RF_FREQ=`echo $LINE | awk '{print $7}'`
	RF_SRC_FREQ=$RF_FREQ
        if [[ `echo $LINE | awk '{print NF}'` -eq 8 ]]; then
        	#Then we've specificed a different source frequency
                RF_SRC_FREQ=`echo $LINE | awk '{print $8}'`
        fi
	#First, see if this is a old format run_ID file
	if [[ "$RF_ERF_ID" -eq "" ]]; then
		#This is not what we're looking for
		continue
	fi 
	#See if this run could plausibly be the one we want
	if [[ "$RF_ERF_ID" -ne "" && "$RF_ERF_ID" -ne "$ERF" ]]; then
		continue
	fi
        if [[ "$RF_SGT_VAR" -ne "" && "$RF_SGT_VAR" -ne "$SGT_VAR" ]]; then
                continue
	fi
        if [[ "$RF_RUP_VAR" -ne "" && "$RF_RUP_VAR" -ne "$RUP_VAR" ]]; then
                continue
	fi
        if [[ "$RF_VEL_ID" -ne "" && "$RF_VEL_ID" -ne "$VEL_ID" ]]; then
                continue
	fi
	if [[ "$RF_FREQ" != "" && "$RF_FREQ" != "$FREQ" ]]; then
		continue
	fi
        if [[ "$RF_SRC_FREQ" != "" && "$RF_SRC_FREQ" != "$SRC_FREQ" ]]; then
                continue
        fi
        FOUND=1
	echo "${ROOT_RUN_DIR}/cybershake-tools/runmanager/valid_run.py ${RUN_ID} ${SITE_NAME} PP_PLAN"
        ${ROOT_RUN_DIR}/cybershake-tools/runmanager/valid_run.py ${RUN_ID} ${SITE_NAME} PP_PLAN
        if [ $? != 0 ]; then
            echo "Run ${RUN_ID} not in expected state"
            exit 1
        fi
	if [[ "$FOUND" -eq "1" ]]; then
		break
	fi
    done < ${RUN_FILE}

    if [[ "${FOUND}" == 0 ]]; then
	#We didn't find a run match.  Create a new run.
        echo "find_run.py ${SITE} ${ERF} ${SGT_VAR} ${RUP_VAR} ${VEL_ID} ${FREQ} ${SRC_FREQ}"
        RUN_ID=`${ROOT_RUN_DIR}/cybershake-tools/runmanager/find_run.py ${SITE} ${ERF} ${SGT_VAR} ${RUP_VAR} ${VEL_ID} ${FREQ} ${SRC_FREQ}`
        if [ $? -ne 0 ]; then
            echo "Failed to find matching run."
            exit 2
        fi
        echo "RUN_ID: ${RUN_ID}"
        echo "${RUN_ID} ${SITE} ${ERF} ${SGT_VAR} ${RUP_VAR} ${VEL_ID} ${FREQ} ${SRC_FREQ}" >> ${RUN_FILE}
        #RUN_ID_STRING=${RUN_ID}
    fi
fi
  
#if [ "${RUN_ID_STRING}" == "" ]; then

RUN_ID_STRING="${RUN_ID}"

#else
#    RUN_ID_STRING="${RUN_ID_STRING} ${RUN_ID}"
#fi

#Create this dir here so the DAX generator has a place to write the rupture file list files
mkdir ${SITE}_PP_dax/run_${RUN_ID}

# Compile the DAX generator
$COMPILE_CMD

if [ $? -ne 0 ]; then
	exit 1
fi


# Run the DAX generator
full_cmd="$RUN_CMD ${RUN_ID_STRING} `pwd`/${SITE}_PP_dax/run_${RUN_ID} ${OPT_ARGS}"
echo $full_cmd
$full_cmd

if [ $? -ne 0 ]; then
	exit 1
fi

#Register rupture file
#pegasus-rc-client insert rupture_file_list_${SITE}_${RUN_ID} file://`pwd`/${SITE}_PP_dax/run_${RUN_ID}/rupture_file_list_${SITE}_${RUN_ID} pool="shock"

#Register rvrfac file, if it exists
#if [ -f ${SITE}_PP_dax/run_${RUN_ID}/rvfrac_seed_values_${SITE}_${RUN_ID} ]; then
#	echo "Registering rvfrac file."
#	pegasus-rc-client insert rvfrac_seed_values_${SITE}_${RUN_ID} file://`pwd`/${SITE}_PP_dax/run_${RUN_ID}/rupture_file_list_${SITE}_${RUN_ID} pool="shock"
#fi

mv CyberShake_${SITE}*.dax ${SITE}_PP_dax/run_${RUN_ID}
mv ${SITE}.db ${SITE}_PP_dax/run_${RUN_ID}
#mv CyberShake_${SITE}.pdax ${SITE}_PP_dax/


# Update comment, for this run
${ROOT_RUN_DIR}/cybershake-tools/runmanager/edit_run.py ${RUN_ID} "Comment=PP DAX created"
if [ $? != 0 ]; then
        echo "Unable to update comment for run ${RUN_ID}"
	exit 1	
fi
