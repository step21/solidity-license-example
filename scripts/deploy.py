from brownie import LicenseContract, accounts

# SolidityStorage, VyperStorage,


def main():
    """ Simple deploy script for our two contracts. """
    accounts[0].deploy(LicenseContract)
    # LicenseContract[0].newLicense((uint256,bytes32,uint8,uint8,bool,bool,uint256,bool,bool,uint256,uint256) _license, {'from': Account})


# (16, )
# license id, work_hash
