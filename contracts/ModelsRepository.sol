pragma solidity ^0.4.4;


contract ModelRepository {

  // IPFS address struct
  struct IPFS {
    bytes32 hash;
    uint8 hashFunction;
    uint8 size;
  }

  // Struct that represents a gradient tree node
  struct Gradient {
    address publisher;
    bool isGradient; // Equals to zero when empty struct.
    IPFS grad;
    IPFS weights;
    uint error;
    uint parent;
    bool evaluated;
  }

  // Struct that represents a model
  struct Model {
    address owner;
    bool isModel; // Equals to zero when empty struct.
    uint bounty;
    uint bestGradient;

    // HACK: Initial error and weights in first gradient.
    uint targetError;
    uint gradientCount;
    mapping(uint => Gradient) gradientMap;
  }

  uint modelCount;
  mapping(uint => Model) models;

  modifier isModel(uint modelId){
    require(models[modelId].isModel);
    _;
  }

  modifier isGradient(uint modelId, uint gradientId){
    require(models[modelId].gradientMap[gradientId].isGradient);
    _;
  }

  function createModel (uint bounty, uint initialError, uint targetError, IPFS ipfsWeights) private returns(Model model) {
    Model memory newModel = Model({
        owner: msg.sender,
        isModel: true,
        bestGradient: 0,
        bounty: bounty,
        targetError: targetError,
        gradientCount: 0
    });
    // Add dummy root gradient
    IPFS memory ipfsInitGrad; // empty address
    models[modelCount].gradientMap[0] = createGradient(msg.sender, ipfsInitGrad, ipfsWeights, initialError, 0);
    return newModel;
  }

  function createGradient (address publisher, IPFS grad, IPFS weights, uint error, uint parent) pure private returns (Gradient gradient) {
    Gradient memory newGradient = Gradient({
        publisher: publisher,
        isGradient: true,
        grad: grad,
        weights: weights,
        error: error,
        parent: parent,
        evaluated: false
    });
    return newGradient;
  }

  function insertModel(uint bounty, uint initialError, uint targetError, bytes32 weightsIPFSHash, uint8 weightsIPFSHashFunction, uint8 weightsIPFSSize) public payable returns (uint newModelId) {
    IPFS memory ipfsWeights = IPFS(weightsIPFSHash, weightsIPFSHashFunction, weightsIPFSSize);
    models[modelCount] = createModel(bounty, initialError, targetError, ipfsWeights);
    modelCount += 1;
    return modelCount-1; // Returns model Id
  }

  function insertGradient(uint modelId, uint parent, bytes32 gradientsIPFSHash, uint8 gradientsIPFSHashFunction, uint8 gradientsIPFSSize) public isModel(modelId) returns (uint newGradientId){
    IPFS memory ipfsWeights; // Empty weights
    IPFS memory ipfsGrad = IPFS(gradientsIPFSHash, gradientsIPFSHashFunction, gradientsIPFSSize);
    models[modelId].gradientMap[models[modelId].gradientCount] = createGradient(msg.sender, ipfsGrad, ipfsWeights, 0, parent);
    models[modelId].gradientCount += 1;
    return models[modelId].gradientCount; // Returns new gradient Id within model
  }

  function getModel(uint modelId) public constant isModel(modelId) returns(address, uint, uint, uint, uint){
      return modelToTuple(models[modelId]);
  }

  function getGradient(uint modelId, uint gradientId) view public isModel(modelId) isGradient(modelId, gradientId) returns (address, bytes32, uint8, bytes32, uint8, uint, uint, bool){
      return gradientToTuple(models[modelId].gradientMap[gradientId]);
  }

  function modelToTuple(Model model) pure private returns (address, uint, uint, uint, uint) {
      return (model.owner, model.bounty, model.bestGradient, model.targetError, model.gradientCount);
  }

  function gradientToTuple(Gradient gradient) pure private returns (address, bytes32, uint8, bytes32, uint8, uint, uint, bool) {
      return (gradient.publisher, gradient.grad.hash, gradient.grad.hashFunction, gradient.weights.hash, gradient.weights.hashFunction, gradient.error, gradient.parent, gradient.evaluated);
  }
}
