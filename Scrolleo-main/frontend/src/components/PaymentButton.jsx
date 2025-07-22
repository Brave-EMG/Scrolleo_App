import React, { useState, useEffect } from 'react';
import Feexpay from '@feexpay/react-sdk';
import axios from 'axios';

const PaymentButton = ({ type, planId, onSuccess, onError }) => {
    const [paymentParams, setPaymentParams] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        const fetchPaymentParams = async () => {
            try {
                const response = await axios.post('/api/payments/params', {
                    type,
                    planId
                });
                setPaymentParams(response.data.feexpayParams);
                setLoading(false);
            } catch (err) {
                setError(err.response?.data?.error || 'Erreur lors du chargement des paramètres de paiement');
                setLoading(false);
            }
        };

        fetchPaymentParams();
    }, [type, planId]);

    if (loading) return <div>Chargement...</div>;
    if (error) return <div className="text-red-500">{error}</div>;
    if (!paymentParams) return null;

    return (
        <Feexpay
            {...paymentParams}
            callback={(response) => {
                if (response.status === 'success') {
                    onSuccess(response);
                } else {
                    onError(response);
                }
            }}
        />
    );
};

export default PaymentButton; 