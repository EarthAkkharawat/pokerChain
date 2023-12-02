import React, { useEffect } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { getEthereumContract, getNFTContract } from '../../utils/contracts';
import './ProfilePicture.css';


// accountAddress อยากได้เป็น global จากหน้า Login มา
const ProfilePicture: React.FC = () => {
    const baseIPSF = 'https://bafybeiahufr3by2rmri7tppip7t523zzfq3fnbvbbczatxgk3zr6kezbsu.ipfs.dweb.link'
    const nftNo = 0;
    const getProfile = async () => {
        try {
            if (window.ethereum) {
                const contract = await getNFTContract();

            }
        } catch (error) {
            console.log(error)
        }
    }

    useEffect(() => {
        getProfile();
    }, [])
    return (
        <>
            <div>Profile Picture</div>
            <img src={`${baseIPSF}/${nftNo}.png`} className='picture' alt="profile" sizes='2' />
        </>
    );
};

export default ProfilePicture;