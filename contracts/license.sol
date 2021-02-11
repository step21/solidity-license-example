// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "contracts/datetime.sol";
import "contracts/Ownable.sol";

/// @title A (software) license evaluation system
/// @author Florian Idelberger
/// @notice A license contract to provide software evaluation licenses and functions to check status
/// @dev require is always used instead of assert so far, to provide an error message and make the code more readable

contract LicenseContract is Ownable {
    uint numLicenses;
    // Constructor
    constructor() {
        // This tracks the number of licenses, here initialized to 0
        numLicenses = 0;
    }

// Events
event LicenseStatus(LicenseContract.License);
event LicenseID(uint licenseID);
event LicenseContractStatus(LicenseContract);
event LicenseFeeStatus(uint256 amount);
event BreachFeeStatus(breachFee bfs);
event SublicenseeStatus(uint numberOfSublicensees);

mapping(uint256 => address) public licensor;
mapping(uint256 => address) public licensee;
mapping(uint256 => address) public arbiter;
mapping(uint256 => License) public licenses;
mapping(uint256 => address[]) public sublicensees;
mapping (address => uint) pendingLicenseFeeWithdrawals;
mapping (address => breachFee) breachFeeStorage;

// This struct ties a brechFee to a license and is necessary
// to track if a breachFee was cleared for withdrawal.
struct breachFee {
    uint256 licenseID;
    bool cleared;
    uint amount;
}

// As far as rules are not set out specifically,
// but only defined imperatively, this struct sets
// out the default rules, in so far without being set,
// the permissions are always false.

struct License {
    //uint256 licenseID; 
    bytes32 workHash; // this might actually not be necessary and could be covered by licenseID but out of scope how this would work it trying to enforce client-side
    uint8 licenseFee;
    uint8 breachFee;
    bool isCommissioned;
    bool publicationIsApproved;
    bool unauthorizedPublication;
    uint timeToRemove;
    uint timeOfNotification;
    bool licenseBreached;
    uint startdate;
    uint enddate;
}

// OnlyBy modifier. Ideally would allow for multiple adresses.
modifier onlyBy(address _account)
    {require(msg.sender == (_account),
          "Sender not authorized.");
        _;}

/// @notice Create a new license and add it to the mapping of licenses.
/// @dev For now licensor is fixed to owner. timeToRemove is assumed to be in days. Wanted to specify a date or timestamp,
// but if anything would have to be a date diff, but to get that would need a date. Is there a difference between built-in + 1 day and addDays in BokkyPooBahsDateTimeLibrary?
/// @param _license passes a license struct.
/// @return _licenseID of the created license.
function newLicense(License memory _license) public onlyOwner returns (uint _licenseID) {
    //require(_license.licenseID != 0, "License ID has to be provided and cannot be 0"); // require license id, license fee, breach fee, startdate and enddate
    require(_license.licenseFee != 0, "License Fee has to be provided and cannot be 0.");
    require(_license.breachFee != 0, "Breach Fee has to be provided and cannot be 0.");
    uint startyear; uint startmonth; uint startday;
    uint endyear; uint endmonth; uint endday;
    (startyear, startmonth, startday) = BokkyPooBahsDateTimeLibrary.timestampToDate(_license.startdate);
    (endyear, endmonth, endday) = BokkyPooBahsDateTimeLibrary.timestampToDate(_license.enddate);
    require(BokkyPooBahsDateTimeLibrary.isValidDate(startyear, startmonth, startday),
        "Seems to be an invalid startdate."
    );
    require(BokkyPooBahsDateTimeLibrary.isValidDate(endyear, endmonth, endday),
        "Seems to be an invalid enddate."
    );
    require(_license.publicationIsApproved == false);
    require(_license.unauthorizedPublication == false);
    require(_license.licenseBreached == false);
    require(_license.timeToRemove > 0, "Time for removal of unauthorized publication has to be greater than 0.");
    LicenseContract.numLicenses++; // starts at 1
    _licenseID = LicenseContract.numLicenses;
     // check if incrementation works
    licensor[_licenseID] = owner();
    licenses[_licenseID] = _license;
    emit LicenseID(_licenseID);
    emit LicenseStatus(_license);
    }

/// @notice 'Sign' the license by assigning a licensee and paying license and breachFee.
/// @dev The successful signing and payment of the fees concludes a valid license.
/// @param _licenseID of the license to be modified, and address of the _licensee to be added
function signLicense(uint _licenseID, address _licensee) public payable onlyBy(msg.sender) {
    require(arbiter[_licenseID] != address(0x0), "No arbiter specified");
    licensee[_licenseID] = _licensee;
    //payable(this.address).send(licenses[_licenseID].licenseFee);
    (bool success, ) = address(this).call{value: licenses[_licenseID].licenseFee}("");
    require(success, "Transfer of license fee failed.");
    pendingLicenseFeeWithdrawals[licensor[_licenseID]] += licenses[_licenseID].licenseFee;
    (bool success_breach, ) = address(this).call{value: licenses[_licenseID].breachFee}("");
    require(success_breach, "Transfer of breach fee failed.");
    breachFeeStorage[licensor[_licenseID]] = breachFee(_licenseID, false, licenses[_licenseID].breachFee);
    emit LicenseStatus(licenses[_licenseID]);
    emit LicenseFeeStatus(pendingLicenseFeeWithdrawals[licensor[_licenseID]]);
    emit BreachFeeStatus(breachFeeStorage[licensor[_licenseID]]);
}

/// @notice Allow withdrawal of license fee.
/// @dev The licensor can withdraw pending license fee(s).
/// @param _licenseID of the relevant license
function withdrawLicenseFee(uint _licenseID) public onlyBy(licensor[_licenseID]) returns (bool success) { // licenseID only used for modifier so maybe could be replaced with msg.sender
        uint amount = pendingLicenseFeeWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingLicenseFeeWithdrawals[msg.sender] = 0;
        (bool success, ) = licensor[_licenseID].call{value: amount}("");
        require(success, "Withdrawal of license fee failed.");
        emit LicenseFeeStatus(pendingLicenseFeeWithdrawals[msg.sender]);
    }

/// @notice This function sets the arbiter
/// @dev Should be set before signing the license.
/// @param _licenseID of the license to be modified and address of the arbiter to be added
function setArbiter(uint _licenseID, address _arbiter) public onlyBy(licensor[_licenseID]) { // onlyOwner
    require(arbiter[_licenseID] == address(0x0), 'Arbiter already set.');
    arbiter[_licenseID] = _arbiter;
    emit LicenseContractStatus(this);
}

/// @notice This adds a sublicensee to an existing license.
/// @dev This takes one address at a time and uses an array mapped to an id, returning number of sublicenses of a license. (in future -  allow adding array of addresses)
/// @param _licenseID of the license to be modified and the address of the arbiter to be added
function addSublicensee(uint _licenseID, address _sublicensee) public onlyBy(licensor[_licenseID]) returns (uint sllenght) {
    require(licensee[_licenseID] != address(0x0), 'License has to be signed before Sublicensees can be added.');
    sublicensees[_licenseID].push(_sublicensee);
    uint sllength = sublicensees[_licenseID].length;
    emit SublicenseeStatus(sllength);
    return sllength; }

/// @notice This commissions comments. It has to be set before signing of the license.
/// @dev TODO - check if this require actually does what it should/include in test // commssion fee left out for now.
//  Would also use withdrawal pattern and also should allow licensor to recover funds if they are not withdranw until a certain point
/// @param _licenseID of the license to be modified
function commissionComments(uint _licenseID) public onlyBy(licensor[_licenseID]) {
    // date before end date
    require(licensee[_licenseID] == address(0x0), 'Unilateral modification is not permitted.');
    //(bool success, ) = address(this).call{value: licenses[_licenseID].commissionFee}("");
    //require(success, "Transfer of commissioning payment failed.");
    licenses[_licenseID].publicationIsApproved = true;
    licenses[_licenseID].isCommissioned = true;
    emit LicenseStatus(licenses[_licenseID]);
    }

/// @notice This grants approval for comments, can be used before or after signing.
/// @dev At present, this is only allowed to be called by the licensor.
/// @param _licenseID of the license to be modified
function grantApproval(uint _licenseID) public onlyBy(licensor[_licenseID]) {
    require(licensee[_licenseID] != address(0x0), 'Does not make sense to grant approval before a signed license.');
    require(block.timestamp > licenses[_licenseID].startdate && block.timestamp < licenses[_licenseID].enddate, "Outside of licensing period.");
    require(licenses[_licenseID].publicationIsApproved == false, "Publication was already approved");
    require(licenses[_licenseID].unauthorizedPublication == false, "Unauthorized publication, no ex-post approval allowed.");
    licenses[_licenseID].publicationIsApproved = true; 
    emit LicenseStatus(licenses[_licenseID]);
    }

/// @notice This sets unauthorizedPublication if an unauthorized publication was noticed.
/// @dev 
/// @param _licenseID of the license 
function setUnauthorizedPublication(uint _licenseID) public onlyBy(licensor[_licenseID]) returns (uint timeOfNotification) {
    require(block.timestamp < licenses[_licenseID].enddate, "License period ended.");
    require(licensee[_licenseID] != address(0x0), 'Does not make sense to have an unauthorized publication before a signed license.');
    require(licenses[_licenseID].unauthorizedPublication == false, "Unauthorized publication already set.");
    require(licenses[_licenseID].publicationIsApproved == false, "Publication is authorized.");
    licenses[_licenseID].unauthorizedPublication = true;
    if (licenses[_licenseID].timeToRemove == 0) {
        licenses[_licenseID].timeToRemove = 24 hours;
    }
    licenses[_licenseID].timeOfNotification = block.timestamp;
    return licenses[_licenseID].timeOfNotification;
}

/// @notice This function clears license states after a removal of unauthorized publication during the removal period.
/// @dev Right now this is only available for the arbiter, but this is not ideal
/// @param _licenseID of the license to be modified
function declareRemoved(uint _licenseID) public onlyBy(arbiter[_licenseID]) {
    require(block.timestamp > licenses[_licenseID].startdate && block.timestamp < licenses[_licenseID].enddate, "Outside of licensing period."); // or not necessary here?
    require(licensee[_licenseID] != address(0x0), 'Successful removal can only be declared on a signed license.');
    require(licenses[_licenseID].unauthorizedPublication == true, "No unauthorized publication recorded.");
    require(block.timestamp < (licenses[_licenseID].timeOfNotification + licenses[_licenseID].timeToRemove), "Removal period lapsed.");
    licenses[_licenseID].timeToRemove = 0;
    licenses[_licenseID].unauthorizedPublication = false;
    emit LicenseStatus(licenses[_licenseID]);
}

/// @notice This declares a breach, and then clears breach fee for withdrawal
/// @dev 
/// @param _licenseID of the license to be modified
function declareBreach(uint _licenseID) public onlyBy(arbiter[_licenseID]) returns (bool success) {
    require(licensee[_licenseID] != address(0x0), 'Does not make sense to declare a breach on an unsigned license.');
    //require(licenses[_licenseID].unauthorizedPublication); // mmmh this would mean only possibility for breach is unauthorized publication
    require(block.timestamp > licenses[_licenseID].startdate && block.timestamp < licenses[_licenseID].enddate, "Outside of licensing period."); // check for the license period
    require(licenses[_licenseID].timeOfNotification + licenses[_licenseID].timeToRemove <= block.timestamp, "The removal period has not yet lapsed.");
    licenses[_licenseID].licenseBreached = true;
    breachFeeStorage[licensor[_licenseID]].cleared = true;
    sublicensees[_licenseID] = [address(0x0)];
    licensee[_licenseID] = address(0x0);
    emit LicenseStatus(licenses[_licenseID]);
    return true;
         }

/// @notice This allows for withdrawal of the breach fee, assuming it is cleared by the arbiter.
/// @dev 
/// @param _licenseID of the license to be modified
function withdrawBreachFee(uint _licenseID) public onlyBy(licensor[_licenseID])  {
        require(breachFeeStorage[msg.sender].cleared == true, "This breach fee has not been cleared and thus cannot be withdrawn, likely there is no breach.");
        uint amount = breachFeeStorage[msg.sender].amount;
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        breachFeeStorage[msg.sender].amount = 0;
        (bool success, ) = licensor[_licenseID].call{value: amount}(""); 
        require(success, "Transfer of breach fee failed.");
    }

/// @notice This allows to 'withdraw' (return) the breach fee if the license was concluded properly.
/// @dev 
/// @param _licenseID of the license that ended
function returnBreachFee(uint _licenseID) public onlyBy(licensee[_licenseID])  {
        require(licensee[_licenseID] != address(0x0), "There is no signed license.");
        require(block.timestamp > licenses[_licenseID].enddate, "The license is still active, the breach fee cannot be returned yet.");
        require(licenses[_licenseID].licenseBreached == false, "License is marked as breached.");
        require(breachFeeStorage[msg.sender].cleared == false, "There was a breach, cannot be withdrawn.");
        uint amount = breachFeeStorage[licensor[_licenseID]].amount; 
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        breachFeeStorage[licensor[_licenseID]].amount = 0;
        (bool success, ) = licensee[_licenseID].call{value: amount}("");
        require(success, "Transfer of breach fee failed.");
    }

/// @notice This checks whether the license is active based on date and other data
/// @dev Here  as this is just a passive function and to try another pattern, if/else etc are used instad of require/assert
/// @param _licenseID of the license to be modified
function licenseActivationStatus(uint _licenseID) public returns (bool status) {
        if (licensor[_licenseID] == address(0x0) ) { // || licenses[_licenseID].licenseID != 0
               status = false;
        } else if (licensee[_licenseID] == address(0x0)) {
            status == false;
        } else if (licenses[_licenseID].licenseBreached == true || block.timestamp > licenses[_licenseID].enddate || block.timestamp < licenses[_licenseID].startdate ) {
            status = false;
        } else if (licenses[_licenseID].timeOfNotification != 0 && block.timestamp > (licenses[_licenseID].timeOfNotification + licenses[_licenseID].timeToRemove) ) {
            declareBreach(_licenseID);
        } else {
            status = true;
        }
        emit LicenseStatus(licenses[_licenseID]);
        return status;
    }

    // for receiving
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

// Note: could also use state machine / at stage model
    