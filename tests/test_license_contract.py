from brownie import accounts, web3, chain
from datetime import datetime, timedelta
import pytest

dt = datetime.now()


@pytest.fixture
def license():
    pass


def test_license_contract_deploy(license_contract):
    """
    Test if the contract is correctly deployed.
    """
    assert license_contract


# @pytest.mark.parametrize(
#    "from_acc",
#    [accounts[0], accounts[1], accounts[2], accounts[3], accounts[4]],
# )
def test_license_contract_newLicense(
    license_contract,
):  # from_acc

    nl = license_contract.newLicense(
        [
            0x9C22FF5F21F0B81B113E63F7DB6DA94FEDEF11B2119B4088B89664FB9A3CB658,  # workHash
            1,  # licenseFee
            2,  # breachFee
            False,  # isCommissioned
            False,  # publicationIsApproved
            False,  # unauthorizedPublication
            4,  # timeToRemove (in days)
            0,
            False,  # licenseBreached
            int(dt.timestamp()),  # startdate # 1612534771, 1614954019
            int(
                datetime(
                    dt.year,
                    (dt.month + 1),
                    dt.day,
                    dt.hour,
                    dt.minute,
                    dt.second,
                    dt.microsecond,
                ).timestamp()
            ),  # enddate
        ],
        {"from": accounts[0]},  # from_acc
    )
    print(nl)
    assert nl


def test_license_contract_right_owner(license_contract):
    t = _new_license(license_contract)
    assert license_contract.licensor(t) == accounts[0]


def test_license_contract_setArbiter(license_contract):
    t = _new_license(license_contract)
    license_contract.setArbiter(
        t,
        accounts[2],
    )  # {"from": accounts[0]})
    assert license_contract.arbiter(t) == accounts[2]


# t.events['LicenseID']['licenseID']

# @given(amount=strategy('uint', max_value=1000)
def test_license_contract_signLicense(license_contract):
    t = _new_license(license_contract)
    license_contract.setArbiter(
        t,
        accounts[2],
    )  # {"from": accounts[0]})
    license_contract.signLicense(
        t,
        accounts[1],
        {
            "value": (
                web3.toWei(
                    (license_contract.licenses(t)[1] + license_contract.licenses(t)[2]),
                    "ether",
                )
            )
        },
    )
    assert license_contract.licensee(t) == accounts[1]


def test_license_contract_addSublicensee(license_contract):
    t = _new_license(license_contract)
    license_contract.setArbiter(
        t,
        accounts[2],
    )  # {"from": accounts[0]})
    license_contract.signLicense(
        t,
        accounts[1],
        {
            "value": (
                web3.toWei(
                    (license_contract.licenses(t)[1] + license_contract.licenses(t)[2]),
                    "ether",
                )
            )
        },
    )

    license_contract.addSublicensee(t, accounts[4])
    # print(license_contract.sublicensees)
    assert license_contract.sublicensees(t, 0) == accounts[4]


def test_license_contract_withdrawLicenseFee(license_contract):
    t = _new_license(license_contract)
    license_contract.setArbiter(
        t,
        accounts[2],
    )  # {"from": accounts[0]})
    license_contract.signLicense(
        t,
        accounts[1],
        {
            "value": (
                web3.toWei(
                    (license_contract.licenses(t)[1] + license_contract.licenses(t)[2]),
                    "ether",
                )
            )
        },
    )
    license_contract.addSublicensee(t, accounts[4])
    old_balance = accounts[0].balance()
    license_contract.withdrawLicenseFee(t, {"from": accounts[0]})
    assert int(accounts[0].balance()) > int(old_balance)


def test_license_contract_comissionComments(license_contract):
    t = _new_license(license_contract)
    license_contract.setArbiter(
        t,
        accounts[2],
    )  # {"from": accounts[0]})
    license_contract.commissionComments(t, {"from": accounts[0]})
    license_contract.signLicense(
        t,
        accounts[1],
        {
            "value": (
                web3.toWei(
                    (license_contract.licenses(t)[1] + license_contract.licenses(t)[2]),
                    "ether",
                )
            )
        },
    )
    assert license_contract.licenses(t)[3] == True


def test_license_contract_grantApproval(license_contract):
    t = _new_license(license_contract)
    license_contract.setArbiter(
        t,
        accounts[2],
    )  # {"from": accounts[0]})
    license_contract.signLicense(
        t,
        accounts[1],
        {
            "value": (
                web3.toWei(
                    (license_contract.licenses(t)[1] + license_contract.licenses(t)[2]),
                    "ether",
                )
            )
        },
    )
    license_contract.grantApproval(t)
    assert license_contract.licenses(t)[4] == True


def test_license_contract_setUnauthorizedPublication(license_contract):
    t = _new_license(license_contract)
    license_contract.setArbiter(
        t,
        accounts[2],
    )  # {"from": accounts[0]})
    license_contract.signLicense(
        t,
        accounts[1],
        {
            "value": (
                web3.toWei(
                    (license_contract.licenses(t)[1] + license_contract.licenses(t)[2]),
                    "ether",
                )
            )
        },
    )
    license_contract.setUnauthorizedPublication(t)
    assert license_contract.licenses(t)[5] == True


def test_license_contract_declareRemoved(license_contract):
    t = _new_license(license_contract)
    license_contract.setArbiter(
        t,
        accounts[2],
    )  # {"from": accounts[0]})
    license_contract.signLicense(
        t,
        accounts[1],
        {
            "value": (
                web3.toWei(
                    (license_contract.licenses(t)[1] + license_contract.licenses(t)[2]),
                    "ether",
                )
            )
        },
    )
    license_contract.setUnauthorizedPublication(t)
    license_contract.declareRemoved(t, {"from": accounts[2]})
    assert license_contract.licenses(t)[5] == False
    assert license_contract.licenses(t)[6] == 0


def test_license_contract_declareBreach(license_contract):
    t = _new_license(license_contract)
    license_contract.setArbiter(
        t,
        accounts[2],
    )  # {"from": accounts[0]})
    license_contract.signLicense(
        t,
        accounts[1],
        {
            "value": (
                web3.toWei(
                    (license_contract.licenses(t)[1] + license_contract.licenses(t)[2]),
                    "ether",
                )
            )
        },
    )
    license_contract.setUnauthorizedPublication(t)
    chain.sleep(license_contract.licenses(t)[6] + 3600)
    chain.mine(3)
    license_contract.declareBreach(t, {"from": accounts[2]})
    # assert
    assert license_contract.licenses(t)[8] == True


# prob also should test if both withdrawing license fee and breach fee works
def test_license_contract_withdrawBreachFee(license_contract):
    t = _new_license(license_contract)
    license_contract.setArbiter(
        t,
        accounts[2],
    )  # {"from": accounts[0]})
    license_contract.signLicense(
        t,
        accounts[1],
        {
            "value": (
                web3.toWei(
                    (license_contract.licenses(t)[1] + license_contract.licenses(t)[2]),
                    "ether",
                )
            )
        },
    )
    # license_contract.withdrawLicenseFee(t, {"from": accounts[0]})
    license_contract.setUnauthorizedPublication(t)
    chain.sleep(license_contract.licenses(t)[6] + 3600)
    chain.mine(3)
    license_contract.declareBreach(t, {"from": accounts[2]})
    chain.sleep(license_contract.licenses(t)[6] + 48000)
    chain.mine(3)
    old_balance = accounts[0].balance()
    license_contract.withdrawBreachFee(t, {"from": accounts[0]})
    assert int(accounts[0].balance()) > int(old_balance)


def test_license_contract_returnBreachFee(license_contract):
    t = _new_license(license_contract)
    license_contract.setArbiter(
        t,
        accounts[2],
    )  # {"from": accounts[0]})
    license_contract.signLicense(
        t,
        accounts[1],
        {
            "value": (
                web3.toWei(
                    (license_contract.licenses(t)[1] + license_contract.licenses(t)[2]),
                    "ether",
                )
            )
        },
    )
    chain.sleep(license_contract.licenses(t)[6] + 4000000)
    old_balance = accounts[1].balance()
    license_contract.returnBreachFee(t, {"from": accounts[1]})
    assert int(accounts[1].balance()) > int(old_balance)


def test_license_contract_activationStatus(license_contract):
    t = _new_license(license_contract)
    license_contract.setArbiter(
        t,
        accounts[2],
    )
    license_contract.commissionComments(t, {"from": accounts[0]})
    license_contract.signLicense(
        t,
        accounts[1],
        {
            "value": (
                web3.toWei(
                    (license_contract.licenses(t)[1] + license_contract.licenses(t)[2]),
                    "ether",
                )
            )
        },
    )
    # runs as arbiter because if it calls declareBreach it needs to be from this - ideally it would not need to be
    res = license_contract.licenseActivationStatus(t, {"from": accounts[2]})
    assert res.return_value == True


def _new_license(license_contract):
    nl = license_contract.newLicense(
        [
            0x9C22FF5F21F0B81B113E63F7DB6DA94FEDEF11B2119B4088B89664FB9A3CB658,
            1,  # licenseFee
            2,  # breachFee
            False,  # isCommissioned
            False,  # publicationIsApproved
            False,  # unauthorizedPublication
            4,  # timeToRemove
            0,  # timeOfNotification
            False,  # licenseBreached
            int(dt.timestamp()),  # startdate
            int(
                datetime(
                    dt.year,
                    (dt.month + 1),
                    dt.day,
                    dt.hour,
                    dt.minute,
                    dt.second,
                    dt.microsecond,
                ).timestamp()
            ),  # enddate
        ],
        {"from": accounts[0]},
    )
    return nl.return_value
