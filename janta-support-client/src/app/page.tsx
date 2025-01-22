'use client';
import { useReadContract } from "thirdweb/react";
import { client } from "./client";
import { getContract } from "thirdweb";
import { CampaignCard } from "./components/CampaignCard";
import { defineChain } from "thirdweb";
import { JANTASUPPORT_FACTORY } from "./constants/contracts";

export default function Home() {
  // Get CrowdfundingFactory contract
  const contract = getContract({
    client,
    chain: defineChain(11155111),
    address: JANTASUPPORT_FACTORY
  });

  // Get all campaigns deployed with CrowdfundingFactory
  const {data: campaigns , isPending } = useReadContract({
    contract,
    method: "function getAllCampaigns() view returns ((address campaignAddress, address owner, string name, uint256 creationTime)[])",
    params: []
  });

  return (
    <main className="mx-auto max-w-7xl px-4 mt-4 sm:px-6 lg:px-8">
      <div className="py-10">
        <h1 className="text-4xl font-bold mb-4">Campaigns:</h1>
        <div className="grid grid-cols-3 gap-4">
    
          {!isPending && campaigns && (
            campaigns.length > 0 ? (
              campaigns.map((campaign) => {
              return  <CampaignCard
                  key={campaign.campaignAddress}
                  campaignAddress={campaign.campaignAddress}
                />
              } )
            ) : (
              <p>No Campaigns</p>
            )
          )}
        </div>
      </div>
    </main>
  );
}