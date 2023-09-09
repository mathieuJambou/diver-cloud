#!/bin/bash

ENVIRONMENT=${1}
PAT_TOKEN=${2}
ENABLE_AGENT=${3}
#ENVIRONMENT="tst"
PRIMARY="primary"
AZDO_PROJECT_NAME="myproject"
AZDO_URL="https://dev.azure.com/myOrganization/"
AZDO_ENVIRONMENT_NAME="app-iaas-$ENVIRONMENT-ia"
#AZDO_AGENT_VERSION="2.169.1"
AZDO_AGENT_HOME="/home/automation/azagent-${ENVIRONMENT}"
INSTALL_AGENT="true"

if [[ $ENABLE_AGENT == false ]];
then
    echo "ENABLE_AGENT set to FALSE... exiting."
    exit
fi

echo '################### Deploying AzDO Environment Agent #####################'
touch ~/azdo.agent.environment.`date +%s`.start

## Get Latest AzDO agent version
AZDO_AGENT_RESPONSE=$(curl -LsS -u user:$PAT_TOKEN -H 'Accept:application/json;api-version=3.0-preview' "$AZDO_URL/_apis/distributedtask/packages/agent?platform=linux-x64")
AZDO_AGENT_URL=$(echo "$AZDO_AGENT_RESPONSE" | jq -r '.value | map([.version.major,.version.minor,.version.patch,.downloadUrl]) | sort | .[length-1] | .[3]')
AZDO_AGENT_VERSION=`echo "$AZDO_AGENT_RESPONSE" | jq -r '.value | map([.version.major,.version.minor,.version.patch,.downloadUrl]) | sort | .[length-1] | .[3]' | grep -o -m 1 [0-9]\.[0-9][0-9][0-9]\.[0-9] | head -1`

echo "AzDO Agent Version    : $AZDO_AGENT_VERSION"
echo "AzDO Agent URL        : $AZDO_AGENT_URL"
echo "Environment Name      : $ENVIRONMENT"

## If in  tst environment, fix AzDO environment name
# Define regex expression for  environment
regex="tst|valdn|eqprod"

if [[ $ENVIRONMENT =~ $regex ]];
then
    AZDO_ENVIRONMENT_NAME="app-IAAS-$ENVIRONMENT"
fi

echo "AzDO Environment Name : $AZDO_ENVIRONMENT_NAME"

## If in DR deployment, move the 'dr' before the -ia
#if [[ $ENVIRONMENT =~ "dr" ]];
#then
#    AZDO_ENVIRONMENT_NAME="echo $AZDO_ENVIRONMENT_NAME  | sed -e 's/dr//g; s/-ia$/-dr-ia/g;'"
#fi

## If second bastion, set tag as secondary
if [[ $HOSTNAME =~ "02" ]];
then
    PRIMARY="secondary"
fi

if [ -d $AZDO_AGENT_HOME ] 
then
    echo "Agent path already exists..."

    cd $AZDO_AGENT_HOME

    echo "Validating agent version..."

    echo $(./config.sh --version)
    if [[ $(./config.sh --version) == $AZDO_AGENT_VERSION ]];
    then
        echo "Agent already use specified version. Ending script here."
        INSTALL_AGENT="false"
    else
        echo "Cleaning up agents before proceeding..."

        sudo ./svc.sh stop
        sudo ./svc.sh uninstall

        ./config.sh remove --auth PAT \
                           --token $PAT_TOKEN \

        rm -R *.* -f
    fi
else
    mkdir $AZDO_AGENT_HOME
    cd $AZDO_AGENT_HOME
fi

if [[ $INSTALL_AGENT == "true" ]];
then
    curl -fkSL -o vstsagent.tar.gz "$AZDO_AGENT_URL";tar -zxvf vstsagent.tar.gz;

    ./config.sh --unattended --replace \
                            --runasservice \
                            --environment \
                            --environmentname "$AZDO_ENVIRONMENT_NAME" \
                            --acceptteeeula \
                            --agent "${HOSTNAME}-${ENVIRONMENT}" \
                            --url $AZDO_URL \
                            --work _work \
                            --projectname "$AZDO_PROJECT_NAME" \
                            --auth PAT \
                            --token $PAT_TOKEN \
                            --addvirtualmachineresourcetags \
                            --virtualmachineresourcetags "$ENVIRONMENT, $PRIMARY"
                            
    sudo ./svc.sh install automation;
    sudo ./svc.sh start;
fi

sudo chown -R automation:automation $AZDO_AGENT_HOME;

touch ~/azdo.agent.environment.`date +%s`.finish
echo '################### Deploying AzDO Environment Agent ends #######################'