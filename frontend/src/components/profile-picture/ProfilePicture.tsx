import React, { useEffect } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { getNFTContract } from '../../utils/contracts';
import { accountAddr } from '../login/Login';
import './ProfilePicture.css';


// accountAddress อยากได้เป็น global จากหน้า Login มา
const ProfilePicture: React.FC = () => {
    const baseIPSF = 'https://bafybeiahufr3by2rmri7tppip7t523zzfq3fnbvbbczatxgk3zr6kezbsu.ipfs.dweb.link'
    let nftNoList: number[] = [1];
    let nftNo = -1;
    const getProfile = async () => {
        try {
            if (window.ethereum) {
                const contract = await getNFTContract();
                const totalSupply = await contract.totalSupply();
                for (let i = 0; i < totalSupply; i++) {
                    contract.ownerOf(i).then((owner) => {
                        console.log(owner)
                        if (owner === accountAddr) {
                            nftNoList.push(i);
                            console.log("Owner")
                        } else {
                            console.log("Not Owner")
                        }
                    })
                }
            }
        } catch (error) {
            console.log(error)
        }
    }

    useEffect(() => {
        getProfile();
        if (nftNoList.length === 0) {
            nftNo = -1;
        }
    }, [])
    return (
        <>
            <div>Profile Picture</div>
            <img src={`${baseIPSF}/${nftNoList[0]}.png`} className='picture' alt="profile" sizes='2' />
        </>
    );
};

export default ProfilePicture;