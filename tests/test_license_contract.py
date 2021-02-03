def test_license_contract_deploy(license_contract):
    """
    Test if the contract is correctly deployed.
    """
    assert license_contract
    # len(license_contract) == 32


def test_license_contract_newLicense(license_contract):

    nl = license_contract.newLicense(
        [
            8,
            0x9C22FF5F21F0B81B113E63F7DB6DA94FEDEF11B2119B4088B89664FB9A3CB658,
            1,
            2,
            False,
            False,
            4,
            False,
            False,
            5,
            55,
        ],
        "0x81431b69B1e0E334d4161A13C2955e0f3599381e",
        {"from": "0x16Fb96a5fa0427Af0C8F7cF1eB4870231c8154B6"},
    )
    print(nl)
    assert nl
    # && int(nl)


# work hash (keccak from 'test')
# 0x9c22ff5f21f0b81b113e63f7db6da94fedef11b2119b4088b89664fb9a3cb658
# 8, '0x9c22ff5f21f0b81b113e63f7db6da94fedef11b2119b4088b89664fb9a3cb658', 0.1, 0.9, false, false, 4, false, false, 5, 55

# l.newLicense(('8', '0x9c22ff5f21f0b81b113e63f7db6da94fedef11b2119b4088b89664fb9a3cb658', '1', '2', False, False, '4', False, False, '5', '55'), {'from': accounts[2]}

# also try new license from non-owner, to check if it get rejected properly
