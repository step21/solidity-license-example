import React, {Component} from "react"
import ReactDOM from "react-dom";
import { Container, Row, Col } from 'react-grid-system';
import './App.css'
import {getWeb3} from "./getWeb3"
import map from "./artifacts/deployments/map.json"
import {getEthereum} from "./getEthereum"
import {
  MetaMaskButton,
  BaseStyles,
  Heading,
  Flex,
  Box,
  Form,
  Input,
  Select,
  Field,
  Button,
  Text,
  Checkbox,
  Radio,
  Card
} from "rimble-ui";
import {ThemeProvider} from 'styled-components';
import NetworkIndicator from '@rimble/network-indicator';
import ConnectionBanner from '@rimble/connection-banner';

class App extends Component {

    state = {
        web3: null,
        accounts: null,
        chainid: null,
        vyperStorage: null,
        vyperValue: 0,
        vyperInput: 0,
        solidityStorage: null,
        solidityValue: 0,
        solidityInput: 0,
    }

    componentDidMount = async () => {

        // Get network provider and web3 instance.
        const web3 = await getWeb3()

        // Try and enable accounts (connect metamask)
        try {
            const ethereum = await getEthereum()
            ethereum.enable()
        } catch (e) {
            console.log(`Could not enable accounts. Interaction with contracts not available.
            Use a modern browser with a Web3 plugin to fix this issue.`)
            console.log(e)
        }

        // Use web3 to get the user's accounts
        const accounts = await web3.eth.getAccounts()

        // Get the current chain id
        const chainid = parseInt(await web3.eth.getChainId())
            
        this.setState({
            web3,
            accounts,
            chainid,
        }, await this.loadInitialContracts) 
        

    }

    loadInitialContracts = async () => {
        if (this.state.chainid <= 42) {
            // Wrong Network!
            return
        }

        const licenseContract = await this.loadContract("dev", "LicenseContract")

        if (!licenseContract ) {
            return
        }

        //const license = await licenseContract.methods.get().call()

        this.setState({
            licenseContract,
            //license,

        })
    }

    loadContract = async (chain, contractName) => {
        // Load a deployed contract instance into a web3 contract object
        const {web3} = this.state

        // Get the address of the most recent deployment from the deployment map
        let address
        try {
            address = map[chain][contractName][0]
        } catch (e) {
            console.log(`Couldn't find any deployed contract "${contractName}" on the chain "${chain}".`)
            return undefined
        }

        // Load the artifact with the specified address
        let contractArtifact
        try {
            contractArtifact = await import(`./artifacts/deployments/${chain}/${address}.json`)
        } catch (e) {
            console.log(`Failed to load contract artifact "./artifacts/deployments/${chain}/${address}.json"`)
            return undefined
        }

        return new web3.eth.Contract(contractArtifact.abi, address)
    }

    changeSolidity = async (e) => {
        const {accounts, licenseContract, license} = this.state
        e.preventDefault()
        const value = parseInt(license)
        if (isNaN(value)) {
            alert("invalid value")
            return
        }
        await licenseContract.methods.set(value).send({from: accounts[0]})
            .on('receipt', async () => {
                this.setState({
                    license: await licenseContract.methods.get().call()
                })
            })
    }

    render() {
        const {
            web3, accounts, chainid,
            licenseContract, license
        } = this.state

        

        if (isNaN(chainid) || chainid <= 42) {
            console.log("<div>Wrong Network! Switch to your local RPC 'Localhost: 8545' in your Web3 provider (e.g. Metamask)</div>");
        }

        if (!licenseContract) {
            console.log("<div>Could not find a deployed contract. Check console for details.</div>");
        }

        const isAccountsUnlocked = accounts ? accounts.length > 0 : false

        return (<div className="App">
            <Container>
                <Row>
                <Col>
            <Heading as="h1">Software License Evaluation Contract.</Heading>
            <p>
                If your contracts compiled and deployed successfully, you can see the current
                storage values below.
            </p>
            {
                !isAccountsUnlocked ?
                    <p><strong>Connect with Metamask and refresh the page to
                        be able to edit the storage fields.</strong>
                    </p>
                    : null
            }
            <Heading>Vyper Storage Contract</Heading>

            <Box>
            <div>The stored value is: {license}</div>
            <br/>
            <form onSubmit={(e) => this.changeVyper(e)}>
                
                    <label>Change the value to: </label>
                    <br/>
                    <input
                        name="vyperInput"
                        type="text"
                        value={license}
                        onChange={(e) => this.setState({license: e.target.value})}
                    />
                    <br/>
                    </form>
                    </Box>
                    </Col>
                    <Col>
                    <NetworkIndicator currentNetwork={null} requiredNetwork={1}>
  {{
    onNetworkMessage: "Connected to correct network",
    noNetworkMessage: "Not connected to anything",
    onWrongNetworkMessage: "Wrong network"
  }}
</NetworkIndicator>
                    <button type="submit" disabled={!isAccountsUnlocked}>Submit</button>
                <MetaMaskButton.Outline size="small">
                    Connect with MetaMask
                    </MetaMaskButton.Outline>
                    </Col>
                </Row>
            <Row>
    <Col sm={4}>
      <Box>
      <Text>
      <Heading>This is a license agreement for a software evaluation license.</Heading>

<Card>*LICENSOR* - Unnamed Software Company.</Card>
<Card>*LICENSEE* - Unnamed University or other Organization.</Card>
*SUBLICENSEE* - A student as set force in the appendix. (array of persons)  
*ARBITER* - An arbiter or oracle that decides in case of disputes.  Can be a natural or legal person or a machine. 
Art.  2, 3 and 4 especially are evaluated by the arbiter in case of disputes.  
*ASSET* - An asset to be licensed.  

* Article 1. The Licensor grants the Licensee  a limited  license  to use  and  evaluate  asset  X  and  grant  sublicenses among group Y, for  use  and  evaluation, in exchange for a licensing fee. This limited license lasts from DD.MM.YYYY (inclusive) to DD.MM.YYYY (exclusive).
* Article 2. (optional) The (Sub)Licensee is commissioned to publish comments about the  use  of  the  product, in exchange for an evaluation fee. This allows publication of comments about the evaluation of *ASSET*. Furthermore, this requires the publication of comments about the evaluation of the *ASSET*.
* Article 3. The (Sub)Licensee must not publish comments of the use and evaluation of the Product without the approval of the Licensor; said approval must be obtained before the publication of comments about the evaluation of *ASSET*. If the Licensee publishes results of the evaluation of the Product without approval from the Licensor, the Licensee has 24 h to remove the material from the time of publication. If the time lapses without a removal of the comments of the evaluation, the license is considered breached.
* Article 4. This license terminates automatically if the Licensee or a sublicensee breaches this license agreement. In case of a breach by the main Licensor, this entails termination of all sublicensees. A breach of the Licensing Terms obliges the Licensee to pay a fee to Licensor for Breach of the Licensing Terms.

      </Text>
      </Box>
    </Col>
    <Col sm={4}>
      One of three columns
    </Col>
    <Col sm={4}>
      One of three columns
    </Col>
  </Row>

</Container>
        </div>)
    }
}

export default App
