import React, { useEffect, useState } from "react";
import { Container, Image } from "react-bootstrap";

import { getNFTContract } from "../../utils/contracts";
import { accountAddr } from "../login/Login";
import "./ProfilePicture.css";

// accountAddress อยากได้เป็น global จากหน้า Login มา
const nftNo = -1;
const baseIPSF =
  "https://bafybeiahufr3by2rmri7tppip7t523zzfq3fnbvbbczatxgk3zr6kezbsu.ipfs.dweb.link";

interface ProfilePictureProps {
  size?: string;
  showName?: boolean;
}

const ProfilePicture: React.FC<ProfilePictureProps> = ({
  size = "250px",
  showName = true,
}) => {
  const [nftNoList, setNftNoList] = useState<number[]>([1]);
  const getProfile = async () => {
    try {
      if (window.ethereum) {
        const contract = await getNFTContract();
        const totalSupply = await contract.totalSupply();
        for (let i = 0; i < totalSupply; i++) {
          contract.ownerOf(i).then((owner) => {
            console.log(owner);
            if (owner === accountAddr) {
              nftNoList.push(i);
              console.log("Owner");
            } else {
              console.log("Not Owner");
            }
          });
        }
      }
    } catch (error) {
      console.log(error);
    }
  };

  useEffect(() => {
    getProfile();
    if (nftNoList.length === 0) {
      // nftNo = -1;
    }
  }, []);
  return (
    <Container className="mb-5">
      <Image
        src={`${baseIPSF}/${nftNoList[0]}.png`}
        className="picture"
        alt="profile"
        // sizes="2"
        style={{ width: size, height: size }}
        roundedCircle
      />
      {showName && <p style={{ color: "#FFFFFF" }}> someName</p>}
    </Container>
  );
};

export default ProfilePicture;
