import React, {Component} from "react"
import ReactDOM from "react-dom";
import './App.css'
import {getWeb3} from "./getWeb3"
import map from "./artifacts/deployments/map.json"
import {getEthereum} from "./getEthereum"
import {
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
import {ThemeProvider} from 'styled-components'

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
            chainid
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

        if (!web3) {
            return <div>Loading Web3, accounts, and contracts...</div>
        }

        if (isNaN(chainid) || chainid <= 42) {
            return <div>Wrong Network! Switch to your local RPC "Localhost: 8545" in your Web3 provider (e.g. Metamask)</div>
        }

        if (!licenseContract) {
            return <div>Could not find a deployed contract. Check console for details.</div>
        }

        const isAccountsUnlocked = accounts ? accounts.length > 0 : false

        return (<div className="App">
            <h1>Your Brownie Mix is installed and ready.</h1>
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
            <h2>Vyper Storage Contract</h2>

            <div>The stored value is: {license}</div>
            <br/>
            <form onSubmit={(e) => this.changeVyper(e)}>
                <div>
                    <label>Change the value to: </label>
                    <br/>
                    <input
                        name="vyperInput"
                        type="text"
                        value={license}
                        onChange={(e) => this.setState({license: e.target.value})}
                    />
                    <br/>
                    <button type="submit" disabled={!isAccountsUnlocked}>Submit</button>
                </div>
            </form>


        </div>)
    }
}

export default App
