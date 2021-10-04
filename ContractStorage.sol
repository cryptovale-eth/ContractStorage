// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ContractStorage{
    address public owner;
    struct Property{
        string[] keys;
        uint256 propertyAmount;
        mapping (string => uint256) keyIndexes;
        mapping (string => string) values;
        mapping (string => string) types;
    }
    struct PropertySet{
        mapping(uint256 => Property) properties;
    }
    
    constructor(){
        owner = msg.sender;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    modifier onlyManagersOrOwner(address contractAddress){
        requireManagersOrOwner(contractAddress);
        _;
    }
    
    function requireManagersOrOwner(address contractAddress) public view{
        require(contractManagers[contractAddress][msg.sender] || msg.sender == owner, "Not a manager");
    }
    
    mapping(address => PropertySet) contractProperties;
    
    mapping(address => mapping(address => bool)) contractManagers;
    
    mapping(address => bool) contractManagerInitialized;
    
    function setContractManagerStatus(address contractAddress, address manager, bool status) public onlyManagersOrOwner(contractAddress){
        contractManagers[contractAddress][manager] = status;
        contractManagerInitialized[contractAddress] = true;
    }
    
    function getPropertyAmount(address contractAddress, uint256 tokenId) public view returns(uint256){
        return contractProperties[contractAddress].properties[tokenId].propertyAmount;
    }
    
    function setProperty(address contractAddress, uint256 tokenId, string memory propertyName, string memory propertyValue, string memory propertyType) public{
        require(bytes(propertyValue).length>0, "Cannot set empty string, use deleteProperty");
        if (bytes(contractProperties[contractAddress].properties[tokenId].values[propertyName]).length == 0){
            // key not known yet
            contractProperties[contractAddress].properties[tokenId].keys.push(propertyName);
            contractProperties[contractAddress].properties[tokenId].keyIndexes[propertyName] = contractProperties[contractAddress].properties[tokenId].propertyAmount;
            contractProperties[contractAddress].properties[tokenId].propertyAmount++;
            // make the caller a manager for the contractProperties, as it is the first caller
            
        }
        if (!contractManagerInitialized[contractAddress]){
                contractManagers[contractAddress][msg.sender] = true;
                contractManagerInitialized[contractAddress] = true;
        }else {
            requireManagersOrOwner(contractAddress);
        }
        // set the value
        contractProperties[contractAddress].properties[tokenId].values[propertyName] = propertyValue;
        contractProperties[contractAddress].properties[tokenId].types[propertyName] = propertyType;
        
        // keep track of indexes and keys
    }
    
    function getProperty(address contractAddress, uint256 tokenId, string memory propertyName)public view returns(string memory propertyValue, string memory propertyType){
        return (contractProperties[contractAddress].properties[tokenId].values[propertyName],
         contractProperties[contractAddress].properties[tokenId].types[propertyName]);
    }
    
    function deleteProperty(address contractAddress, uint256 tokenId, string memory propertyName) public onlyManagersOrOwner(contractAddress){
        // if last key, just delete it
        require(contractProperties[contractAddress].properties[tokenId].propertyAmount > 0, "No properties");
        if (contractProperties[contractAddress].properties[tokenId].propertyAmount > 1){
            // more than one key, we need to move the last into the position of the deleted one
            string memory lastKey = contractProperties[contractAddress].properties[tokenId].keys[contractProperties[contractAddress].properties[tokenId].propertyAmount-1];
            uint256 keyToDelete = contractProperties[contractAddress].properties[tokenId].keyIndexes[propertyName];
            // replace with last one
            contractProperties[contractAddress].properties[tokenId].keys[keyToDelete] = lastKey;
            // change the index
            contractProperties[contractAddress].properties[tokenId].keyIndexes[lastKey] = keyToDelete;
        }
        // remove the last one
        contractProperties[contractAddress].properties[tokenId].keys.pop();
        contractProperties[contractAddress].properties[tokenId].propertyAmount--;
        contractProperties[contractAddress].properties[tokenId].values[propertyName] ="";
        contractProperties[contractAddress].properties[tokenId].types[propertyName] = "";
    }
    
    function getProperties(address contractAddress, uint256 tokenId)public view returns(string[] memory properties, string[] memory values, string[] memory types){
        string[] memory helperKeys = new string[](contractProperties[contractAddress].properties[tokenId].propertyAmount);
        string[] memory helperValues = new string[](contractProperties[contractAddress].properties[tokenId].propertyAmount);
        string[] memory helperTypes = new string[](contractProperties[contractAddress].properties[tokenId].propertyAmount);
        
        for (uint256 i=0; i<contractProperties[contractAddress].properties[tokenId].propertyAmount; i++ ){
            string memory actualPropertyName = contractProperties[contractAddress].properties[tokenId].keys[i];
            helperKeys[i]  = actualPropertyName;
            helperValues[i]  = contractProperties[contractAddress].properties[tokenId].values[actualPropertyName];
            helperTypes[i] = contractProperties[contractAddress].properties[tokenId].types[actualPropertyName];
        }
        return (helperKeys, helperValues, helperTypes);
    }

}
