const {MerkleTree} = require("merkletreejs")
const keccak256 = require("keccak256")

let addresses = [
    "0x9aF61f50a47CBB52Ac21C96825E136222Ad31De1",
    "0xe253b7dFc6239aFDc5Cb6721FE069b741759f389",
]

// Hash addresses to get the leaves
let leaves = addresses.map(addr => keccak256(addr))

// Create tree
let merkleTree = new MerkleTree(leaves, keccak256, {sortPairs: true})
// Get root
let rootHash = merkleTree.getRoot().toString('hex')

// Pretty-print tree
console.log("roothash: ", merkleTree.toString())

// 'Serverside' code
let address = addresses[0]
let hashedAddress = keccak256(address)
let proof = merkleTree.getHexProof(hashedAddress)
console.log("proof: ", proof)

// Check proof
let v = merkleTree.verify(proof, hashedAddress, rootHash)
console.log(v) // returns true