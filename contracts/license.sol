// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

//import "BokkyPooBahsDateTimeLibrary/contracts/BokkyPooBahsDateTimeLibrary.sol";
import "contracts/Ownable.sol";
import "contracts/console.sol";
//import "@openzeppelin/contracts/access/Roles.sol";

/// @title A (software) license evaluation system
/// @author Florian Idelberger
/// @notice A license contract to provide software evaluation licenses and functions to check status
/// @dev //@TODO payment of owner and withdrawal of balance not implemented. transfer possible via ownable.sol

contract LicenseContract is Ownable {
    uint numLicenses;
    // Constructor
    constructor() {
        // This tracks the number of licenses, here initialized to 0
        numLicenses = 0;
    }

// Events
event Status(LicenseContract.License);

mapping(uint256 => address) public licensor;
mapping(uint256 => address) public licensee;
mapping(uint256 => address) public arbiter;
mapping(uint256 => License) public licenses;
mapping(uint256 => address[]) public sublicensees;

// As far as rules are not set out specifically,
// but only defined imperatively, this struct sets
// out the default rules, in so far without being set,
// the permissions are always false. To better show 
// this, I might put them into a seperate struct.

struct License {
    uint256 licenseID; 
    bytes32 workHash;
    uint8 licenseFee;
    uint8 breachFee;
    bool isCommissioned;
    bool publicationIsApproved;
    bool unauthorizedPublication;
    uint timeToRemove;
    bool licenseBreached;
    bool breachFeePaid;
    uint startdate;
    uint enddate;
    
}

modifier onlyBy(address _account)
    {require(msg.sender == (_account),
          "Sender not authorized.");
        _;}

/// @notice Create a new license and add it to the mapping of licenses.
/// @dev For now licensor is fixed to owner.
/// @param _license passes a license struct.
/// @return _licenseID of the created license.
function newLicense(License memory _license) public onlyOwner returns (uint _licenseID) {
    _licenseID = LicenseContract.numLicenses;
    LicenseContract.numLicenses++;
    // why is this not outputted in brownie?
    console.log(_licenseID);
    licensor[_licenseID] = owner();
    licenses[_licenseID] = _license;
    console.log(block.timestamp);
    emit Status(_license);
    return _licenseID; }
    // make sure it is properly returned and emitted
    // @TODO differentiate between record for a work and the 'signing' of the license by licensee

/// @notice 'Sign' the license by assigning a licensee and paying license and breachFee
/// @dev 
/// @param _licenseID of the license to be modified
function signLicense(uint _licenseID, address _licensee) public onlyBy(tx.origin) returns (bool success) {
    // assign licensee FIXME: instead of onlyBy, could just assing tx.origin?
    licensee[_licenseID] = _licensee;
    payable(licensee[_licenseID]).transfer(licenses[_licenseID].licenseFee);
    emit Status(_license);
    // breachFee? any other checks?
    return true;
}

/// @notice 
/// @dev 
/// @param _licenseID of the license to be modified
function setArbiter(uint _licenseID, address _arbiter) public returns (bool success) {
    arbiter[_licenseID] = _arbiter;
    return true;
    emit Status(licenses[_licenseID]);
    // In theory arbiter could also get a fee and similar, but this is very out of scope.
}


/// @notice 
/// @dev 
/// @param _licenseID of the license to be modified
function addSublicensee(uint _licenseID, address _sublicensee) public returns (uint sllenght) {
    //License storage lic = licenses[_licenseID];
    sublicensees[_licenseID].push(_sublicensee);
    sllength = sublicensees[_licenseID].length;
    console.log(sllength);
    emit Status(licenses[_licenseID]);
    return sllength;
}

/// @notice 
/// @dev 
/// @param _licenseID of the license to be modified
function commissionComments(uint _licenseID) public onlyBy(licensor[_licenseID]) {
    License storage lic = licenses[_licenseID]; // FIXME replace by one line
    lic.publicationIsApproved = true;
    lic.isCommissioned = true;
    emit Status(licenses[_licenseID]);
    // @TODO * emit / console log output
    // * make sure changes are saved
    // * (such as tests)
    }

/// @notice This grants approval for comments
/// @dev Compared to the original this is giving approval but is not a rule not to do it.
/// @param _licenseID of the license to be modified
function grantApproval(uint _licenseID) public onlyBy(licensor[_licenseID]) returns (bool success) {
    // @TODO check if was triggered and time?
    License storage lic = licenses[_licenseID]; // FIXME replace by one line
    lic.publicationIsApproved = true; 
    emit Status(licenses[_licenseID]);
    return true;
    }
    // TODO
    // * emit / console.log output
    // * make sure changes are saved
    // * add tests

/// @notice set status if unauthorized publication was noticed
/// @dev 
/// @param _licenseID of the license 
function setUnauthorizedPublication(uint _licenseID) public onlyBy(licensor[_licenseID]) returns (bool success) {
    licenses[_licenseID].unauthorizedPublication = true;

}

/// @notice To 
/// @dev 
/// @param _licenseID of the license to be modified
function declareRemoved(uint _licenseID) public onlyBy(arbiter[_licenseID]) returns (bool success) {
    License storage lic = licenses[_licenseID]; // FIXME replace by one line
    lic.timeToRemove = 0;
    licenses[_licenseID].unauthorizedPublication = false;
    emit Status(licenses[_licenseID]);
    return true;
    //l.triggeredTimeToRemove = false;
}

/// @notice 
/// @dev 
/// @param _licenseID of the license to be modified
function declareBreach(uint _licenseID) public onlyBy(arbiter[_licenseID]) returns (bool success) {
    License storage lic = licenses[_licenseID]; // FIXME replace by one line
    lic.licenseBreached = true;
    if (!(lic.breachFeePaid)) {
        //console.log('breachfeepaid is %s', l.breachFeePaid);
        lic.breachFeePaid = false;
        payable(licensor[_licenseID]).transfer(lic.breachFee);
        // this cannot be enforced so would have to be paid on creation...?
        // or by seperate transaction signing/ agreeing to license
        }    

        emit Status(_license);
         } 

    // renounceOwnership or kill contract?

// @TODO set sublicensees to none on termination?

// @ add / check if setter/getter for everything
// @TODO check if we need this function and test etc...
/// @notice 
/// @dev 
/// @param _licenseID of the license to be modified
function evalPublication(uint _licenseID, bool isPublished) public { // arbiter or owner?
    License storage lic = licenses[_licenseID];
    if (isPublished) {
        if ((isPublished && !lic.isCommissioned || !lic.publicationIsApproved) ) { // &&!triggerTimetoRempove
            lic.timeToRemove = block.timestamp;
            //l.triggeredTimeToRemove = true;
        } else if (block.timestamp > lic.timeToRemove + 1 days ) { //l.triggeredTimeToRemove && B...
            declareBreach(_licenseID);
        }    }
    emit Status(lic); }

    }
