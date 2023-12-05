import React, { useEffect, useState } from "react";
import { Container, Image, Row } from "react-bootstrap";
import { Navigate, useLocation } from 'react-router-dom';
import { getNFTContract } from '../../utils/contracts';
// import { accountAddr } from '../login/Login';
import './ProfilePicture.css';
interface ProfilePictureProps {
    size?: string;
    showName?: boolean;
}

const ProfilePicture: React.FC<ProfilePictureProps> = ({
    size = "250px",
    showName = true,
}) => {
    const baseIPSF = 'https://bafybeife54yhvhxgyvxbsqvwpw5d2ayr4umsqdwwbupn4tlqh7ud4qf6zi.ipfs.dweb.link'
    const accountAddr = localStorage.getItem('accountAddr');
    let nftNo = -1;
    const [nftNoList, setNftNoList] = useState<number[]>([0]);
    useEffect(() => {
        getProfile();
        allProfilePicture();
        if (nftNoList?.length === 0) {
            nftNo = -1;
        }
    }, [])
    // Get profile picture that user has owned
    const getProfile = async () => {
        try {
            if (window.ethereum) {
                const contract = await getNFTContract();

                const totalSupply = await contract.MAX_SUPPLY();
                for (let i = 0; i < totalSupply; i++) {
                    contract.ownerOf(i).then((owner) => {
                        if (owner === accountAddr) {
                            // console.log("owner", i)
                            var temp = nftNoList;

                            setNftNoList(insertIfNotExist(temp, i));
                            setNftNoList(prevList => insertIfNotExist([...prevList], i));
                        }
                    })
                }
            }
        } catch (error) {
            console.log(error);
        }

    }
    const insertIfNotExist = (arr: number[], nftNo: number) => {
        console.log("arr", arr.indexOf(nftNo))
        if (arr.indexOf(nftNo) === -1) {
            arr.push(nftNo);
        }
        return arr;
    }

    const allProfilePicture = () => {
        console.log("nftNoList", nftNoList)
        // if (nftNoList) {
        return (
            <>
                <div className="account-address" style={{ paddingTop: "100px", paddingBottom: "10px" }}>
                    Player Address: {accountAddr}
                </div>
                {nftNoList.map((nftNo) => (
                    <Image src={`${baseIPSF}/${nftNo}.png`} className='picture' alt="profile" style={{ width: size, height: size, paddingLeft: "10px" }} roundedCircle />
                ))}
            </>
        )
        // }
    }

    useEffect(() => {
        getProfile();
        if (nftNoList.length === 0) {
            // nftNo = -1;
        }
    }, []);
    return (
        <Container fluid className="mb-5">
            {allProfilePicture()}
            {showName && <p style={{ color: "#FFFFFF" }}> someName</p>}
        </Container>
    );
};

export default ProfilePicture;
