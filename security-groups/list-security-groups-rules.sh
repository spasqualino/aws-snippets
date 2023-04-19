#!/bin/bash

echo "AWS_PROFILE: ${AWS_PROFILE}"

fileName="security-groups-rules.txt"
if [ ! -z "$AWS_PROFILE" ]
then
    fileName="${AWS_PROFILE}-${fileName}"
fi

echo 'environment;region;groupId;groupName;groupDescription;type;ipProtocol;fromPort;toPort;ipRanges;ipv6Ranges;prefixListIds;userIdGroupPairId;useridGroupPairDescription' > $fileName

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
        description=$(_jq '.Description')

        inboundRules=$(_jq '.IpPermissions')
        for inboundRule in $(echo "${inboundRules}" | jq -r '.[]? | @base64'); do
            _jqInboundRule() {
                echo ${inboundRule} | base64 --decode | jq -r ${1}
            }
            type="Inbound/Ingress"
            ipProtocol=$(_jqInboundRule '.IpProtocol')
            fromPort=$(_jqInboundRule '.FromPort')
            toPort=$(_jqInboundRule '.ToPort')
            ipRanges=$(_jqInboundRule '.IpRanges' | jq -r '.[] | {CidrIp,Description} | join(":")')
            ipv6Ranges=$(_jqInboundRule '.Ipv6Ranges' | jq -r '.[].CidrIpv6') 
            prefixListIds=$(_jqInboundRule '.PrefixListIds' | jq -r '.[].PrefixListId')  

            userIdGroupPairId=""
            useridGroupPairDescription=""
            userIdGroupPairsCount=$(_jqInboundRule '.UserIdGroupPairs' | jq -r ['.[].GroupId'] | jq '. | length')

            if [ $userIdGroupPairsCount -eq 0 ]
            then
                echo $environment';'$region';'$groupId';'$groupName';'$description';'$type';'$ipProtocol';'$fromPort';'$toPort';'$ipRanges';'$ipv6Ranges';'$prefixListIds';'$userIdGroupPairId';'$useridGroupPairDescription >> $fileName
            else
                userIdGroupPairs=$(_jqInboundRule '.UserIdGroupPairs') 
                for userIdGroupPair in $(echo "${userIdGroupPairs}" | jq -r '.[]? | @base64'); do
                    _jqUserIdGroupPair() {
                        echo ${userIdGroupPair} | base64 --decode | jq -r ${1}
                    }
                    userIdGroupPairId=$(_jqUserIdGroupPair '.GroupId')
                    useridGroupPairDescription=$(_jqUserIdGroupPair '.Description')
                    
                    echo $environment';'$region';'$groupId';'$groupName';'$description';'$type';'$ipProtocol';'$fromPort';'$toPort';'$ipRanges';'$ipv6Ranges';'$prefixListIds';'$userIdGroupPairId';'$useridGroupPairDescription >> $fileName
                done
            fi
        done

        inboundRules=$(_jq '.IpPermissionsEgress')
        for inboundRule in $(echo "${inboundRules}" | jq -r '.[]? | @base64'); do
            _jqInboundRule() {
                echo ${inboundRule} | base64 --decode | jq -r ${1}
            }
            type="Outbound/Egress"
            ipProtocol=$(_jqInboundRule '.IpProtocol')
            fromPort=$(_jqInboundRule '.FromPort')
            toPort=$(_jqInboundRule '.ToPort')
            ipRanges=$(_jqInboundRule '.IpRanges' | jq -r '.[].CidrIp')
            ipv6Ranges=$(_jqInboundRule '.Ipv6Ranges' | jq -r '.[].CidrIpv6') 
            prefixListIds=$(_jqInboundRule '.PrefixListIds' | jq -r '.[].PrefixListId')  

            userIdGroupPairId=""
            useridGroupPairDescription=""
            userIdGroupPairsCount=$(_jqInboundRule '.UserIdGroupPairs' | jq -r ['.[].GroupId'] | jq '. | length')

            if [ $userIdGroupPairsCount -eq 0 ]
            then
                echo $environment';'$region';'$groupId';'$groupName';'$description';'$type';'$ipProtocol';'$fromPort';'$toPort';'$ipRanges';'$ipv6Ranges';'$prefixListIds';'$userIdGroupPairId';'$useridGroupPairDescription >> $fileName
            else
                userIdGroupPairs=$(_jqInboundRule '.UserIdGroupPairs') 
                for userIdGroupPair in $(echo "${userIdGroupPairs}" | jq -r '.[]? | @base64'); do
                    _jqUserIdGroupPair() {
                        echo ${userIdGroupPair} | base64 --decode | jq -r ${1}
                    }
                    userIdGroupPairId=$(_jqUserIdGroupPair '.GroupId')
                    useridGroupPairDescription=$(_jqUserIdGroupPair '.Description')
                    
                    echo $environment';'$region';'$groupId';'$groupName';'$description';'$type';'$ipProtocol';'$fromPort';'$toPort';'$ipRanges';'$ipv6Ranges';'$prefixListIds';'$userIdGroupPairId';'$useridGroupPairDescription >> $fileName
                done
            fi
        done
    done

    echo ""
done