async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying from:", deployer.address);

  // 1) SellerRating
  const Rating = await ethers.getContractFactory("SellerRating");
  const rating = await Rating.deploy();
  await rating.deployed();
  console.log("SellerRating:", rating.address);

  // 2) DisputeResolver
  const Resolver = await ethers.getContractFactory("DisputeResolver");
  const resolver = await Resolver.deploy(rating.address);
  await resolver.deployed();
  console.log("DisputeResolver:", resolver.address);

  // 3) EscrowFactory
  const Factory = await ethers.getContractFactory("EscrowFactory");
  const factory = await Factory.deploy(rating.address, resolver.address);
  await factory.deployed();
  console.log("EscrowFactory:", factory.address);

}
main()
  .then(() => process.exit(0))
  .catch(err => { console.error(err); process.exit(1); });
