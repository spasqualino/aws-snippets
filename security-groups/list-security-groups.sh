#!/bin/bash

echo "AWS_PROFILE: ${AWS_PROFILE}"

fileName="security-groups.txt"
if [ ! -z "$AWS_PROFILE" ]
then
    fileName="${AWS_PROFILE}-${fileName}"
fi

echo 'environment;region;groupId;groupName;vpcId;description;ownerId;inboundRulesCount;outboundRulesCount;tagsString;hasNetworkAssociated' > $fileName

for region in $(aws ec2 describe-regions --all-regions --query "Regions[].{Name:RegionName}" --output text);
do
    echo "===== $region ====="
    
    securityGroupsString=$(aws ec2 describe-security-groups --region $region --output json --no-paginate --no-cli-pager)
    securityGroups=$(jq -r '.SecurityGroups' <<<"$securityGroupsString")

    for row in $(echo "${securityGroups}" | jq -r '.[] | @base64'); do

        _jq() {
            echo ${row} | base64 --decode | jq -r ${1}
        }

        environment=$AWS_PROFILE
        groupId=$(_jq '.GroupId')
        echo "Processing group ${groupId}"

        groupName=$(_jq '.GroupName')
        vpcId=$(_jq '.VpcId')
        description=$(_jq '.Description')
        ownerId=$(_jq '.OwnerId')
        inboundRulesCount=$(_jq '.IpPermissions' | jq -r ['.[].IpProtocol'] | jq '. | length')
        outboundRulesCount=$(_jq '.IpPermissionsEgress' | jq -r ['.[].IpProtocol'] | jq '. | length')
        tags=$(_jq '.Tags')
        tagsString=""

        # ===== Get Tags
        for tag in $(echo "${tags}" | jq -r '.[]? | @base64'); do
            _jqtag() {
                echo ${tag} | base64 --decode | jq -r ${1}
            }
            tagKey=$(_jqtag '.Key')
            tagValue=$(_jqtag '.Value')
            tagsString="${tagsString}${tagKey}:${tagValue},"
        done
        # =====

        # ===== Validate if this secutiyGroup has a network interface associated
        hasNetworkAssociated=false

        networkInterfacesString=$(aws ec2 describe-network-interfaces --filters Name=group-id,Values=$groupId --region $region --output json)
        networkInterfaces=$(jq -r '.NetworkInterfaces' <<<"$networkInterfacesString")

        if [ "$networkInterfaces" != "[]" ]
        then
            hasNetworkAssociated=true
        fi
        # ===== 

        echo "$environment;$region;$groupId;$groupName;$vpcId;$description;$ownerId;$inboundRulesCount;$outboundRulesCount;$tagsString;$hasNetworkAssociated" >> $fileName        
    done

    echo ""
done