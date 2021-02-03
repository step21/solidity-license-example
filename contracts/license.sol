// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

//import "BokkyPooBahsDateTimeLibrary/contracts/BokkyPooBahsDateTimeLibrary.sol";
import "contracts/Ownable.sol";
import "contracts/console.sol";
//import "@openzeppelin/contracts/access/Roles.sol";

/// @title A software evaluation license system
/// @author Florian Idelberger
/// @notice A license contract to provide software evaluation licenses and functions to check status
/// @dev //@TODO payment of owner and withdrawal of balance not implemented. transfer possible via ownable.sol

contract LicenseContract is Ownable {

    // Constructor
    function LicenseContractManager() public {
        //uint[] public licensesList;
        //uint numLicenses;
    }

// Events
event Status(LicenseContract.License);

mapping(uint256 => address) public licensor;
mapping(uint256 => address) public licensee;
//@TODO set arbiter in newLicense or later
mapping(uint256 => address) public arbiter;
mapping(uint256 => License) public licenses;

struct License {
    uint256 licenseID;
    bytes32 work_hash;
    uint8 licenseFee;
    uint8 breachFee;
    bool isCommissioned;
    bool publicationIsApproved;
    // can this be set to default value?
    uint timeToRemove;
    bool licenseBreached;
    bool breachFeePaid;
    uint startdate;
    uint enddate;
}

// could also use roles but... simpler for now
modifier onlyBy(address _account)
    {require(msg.sender == (_account),
          "Sender not authorized.");
        _;}

/// @notice Create a new license and add it to the mapping of licenses.
/// @dev T
/// @param _license pass a license struct
/// @return _licenseID of the created license.
//@TODO change all to uint probbaly
function newLicense(License memory _license, address _licensee) public onlyOwner returns (uint _licenseID) {
    // uint256 _licenseTerm, uint8 _licenseFee, uint8 _breachFee, bool _isCommissioned, bool _publicationIsApproved, bool _requiresComments, uint _timeToRemove, bool _triggeredTimeToRemove, bool _licenseBreached, bool _breachFeePaid, uint _startdate, uint _enddate
  // add some checks etc....
  // this did not make logical sense as licensee was not set ...
  //payable(licensee[_licenseID]).transfer(_license.licenseFee);
    
        licensor[_licenseID] = owner();
        
        licensee[_licenseID] = _licensee;
        
        licenses[_licenseID] = _license;
        
        //_isCommissioned, _publicationIsApproved, _requiresComments, _timeToRemove, _triggeredTimeToRemove, _licenseBreached, _breachFeePaid, _startdate, _enddate);
        // sublicensees = _sublicensees;
        return _licenseID; }

/// @notice 
/// @dev 
/// @param _licenseID of the license to be modified
function commissionComments(uint _licenseID) public onlyBy(licensor[_licenseID]) {
    License storage l = licenses[_licenseID];
    l.publicationIsApproved = true;
    l.isCommissioned = true; }

/// @notice 
/// @dev 
/// @param _licenseID of the license to be modified
function grantApproval(uint _licenseID) public onlyBy(licensor[_licenseID]) {
    License storage l = licenses[_licenseID];
    l.publicationIsApproved = true; }

/// @notice 
/// @dev 
/// @param _licenseID of the license to be modified
function evalPublication(uint _licenseID, bool isPublished) public {
    License storage l = licenses[_licenseID];
    if (isPublished) {
        if ((isPublished && !l.isCommissioned || !l.publicationIsApproved) ) { // &&!triggerTimetoRempove
            l.timeToRemove = block.timestamp;
            //l.triggeredTimeToRemove = true;
        } else if (block.timestamp > l.timeToRemove + 1 days ) { //l.triggeredTimeToRemove && B...
            declareBreach(_licenseID);
        }    }
    emit Status(l); }

/// @notice 
/// @dev 
/// @param _licenseID of the license to be modified
function declareRemoved(uint _licenseID) public onlyBy(arbiter[_licenseID]) {
    License storage l = licenses[_licenseID];
    l.timeToRemove = 0;
    //l.triggeredTimeToRemove = false;
}

/// @notice 
/// @dev 
/// @param _licenseID of the license to be modified
function declareBreach(uint _licenseID) public onlyBy(arbiter[_licenseID]) {
    License storage l = licenses[_licenseID];
    l.licenseBreached = true;
    if (!(l.breachFeePaid)) {
        //console.log('breachfeepaid is %s', l.breachFeePaid);
        l.breachFeePaid = false;
        payable(licensor[_licenseID]).transfer(l.breachFee);
        }     } }
