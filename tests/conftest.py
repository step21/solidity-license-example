import pytest


@pytest.fixture(autouse=True)
def setup(fn_isolation):
    """
    Isolation setup fixture.
    This ensures that each test runs against the same base environment.
    """
    pass


@pytest.fixture(scope="module")
def license_contract(accounts, LicenseContract):
    """
    Yield a `Contract` object for the LicenseContract contract.
    """
    yield accounts[0].deploy(LicenseContract)
