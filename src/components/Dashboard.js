import React, { useState, useEffect } from 'react';
import {
    Container,
    Grid,
    Card,
    CardContent,
    Typography,
    Button,
    Box,
    CircularProgress,
    Chip,
    List,
    ListItem,
    ListItemText,
    Divider
} from '@mui/material';
import { LocationOn, AccessTime, Restaurant } from '@mui/icons-material';
import axios from 'axios';

const Dashboard = () => {
    const [foodTruck, setFoodTruck] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        fetchFoodTruckData();
    }, []);

    const fetchFoodTruckData = async () => {
        try {
            const token = localStorage.getItem('token');
            if (!token) {
                setError('Please login first');
                setLoading(false);
                return;
            }
            console.log('Fetching with token:', token); // Debug log
            const response = await axios.get('http://localhost:3001/api/foodtrucks/my-truck', {
                headers: { Authorization: `Bearer ${token}` }
            });
            console.log('Food truck data:', response.data); // Debug log
            setFoodTruck(response.data);
            setLoading(false);
        } catch (err) {
            console.error('Error fetching food truck:', err); // Debug log
            setError(err.response?.data?.message || 'Error fetching food truck data');
            setLoading(false);
        }
    };

    const handleUpdateLocation = async (location) => {
        try {
            const token = localStorage.getItem('token');
            await axios.put('http://localhost:3001/api/foodtrucks/' + foodTruck._id + '/location', location, {
                headers: { Authorization: `Bearer ${token}` }
            });
            fetchFoodTruckData();
        } catch (err) {
            setError(err.response?.data?.message || 'Error updating location');
        }
    };

    if (loading) {
        return (
            <Box display="flex" justifyContent="center" alignItems="center" minHeight="80vh">
                <CircularProgress />
            </Box>
        );
    }

    if (error) {
        return (
            <Box display="flex" justifyContent="center" alignItems="center" minHeight="80vh">
                <Typography color="error">{error}</Typography>
            </Box>
        );
    }

    return (
        <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
            <Grid container spacing={3}>
                {/* Business Information */}
                <Grid item xs={12} md={6}>
                    <Card>
                        <CardContent>
                            <Typography variant="h5" gutterBottom>
                                Business Information
                            </Typography>
                            <Typography variant="body1">
                                <strong>Name:</strong> {foodTruck?.businessName}
                            </Typography>
                            <Typography variant="body1">
                                <strong>Phone:</strong> {foodTruck?.phoneNumber}
                            </Typography>
                            <Typography variant="body1">
                                <strong>Description:</strong> {foodTruck?.description || 'No description available'}
                            </Typography>
                        </CardContent>
                    </Card>
                </Grid>

                {/* Location */}
                <Grid item xs={12} md={6}>
                    <Card>
                        <CardContent>
                            <Typography variant="h5" gutterBottom>
                                <LocationOn /> Current Location
                            </Typography>
                            <Typography variant="body1">
                                <strong>City:</strong> {foodTruck?.location?.city || 'Not set'}
                            </Typography>
                            <Typography variant="body1">
                                <strong>State:</strong> {foodTruck?.location?.state || 'Not set'}
                            </Typography>
                            <Typography variant="body1">
                                <strong>Coordinates:</strong> {foodTruck?.location?.coordinates?.join(', ') || 'Not set'}
                            </Typography>
                            <Button 
                                variant="contained" 
                                color="primary" 
                                sx={{ mt: 2 }}
                                onClick={() => handleUpdateLocation({
                                    latitude: 37.7749,
                                    longitude: -122.4194,
                                    city: "San Francisco",
                                    state: "CA"
                                })}
                            >
                                Update Location
                            </Button>
                        </CardContent>
                    </Card>
                </Grid>

                {/* Operating Hours */}
                <Grid item xs={12} md={6}>
                    <Card>
                        <CardContent>
                            <Typography variant="h5" gutterBottom>
                                <AccessTime /> Operating Hours
                            </Typography>
                            <List>
                                {foodTruck?.businessHours?.map((hours, index) => (
                                    <React.Fragment key={hours.day}>
                                        <ListItem>
                                            <ListItemText
                                                primary={hours.day}
                                                secondary={`${hours.open} - ${hours.close}`}
                                            />
                                        </ListItem>
                                        {index < foodTruck.businessHours.length - 1 && <Divider />}
                                    </React.Fragment>
                                ))}
                            </List>
                        </CardContent>
                    </Card>
                </Grid>

                {/* Food Types */}
                <Grid item xs={12} md={6}>
                    <Card>
                        <CardContent>
                            <Typography variant="h5" gutterBottom>
                                <Restaurant /> Food Types
                            </Typography>
                            <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                                {foodTruck?.foodTypes?.map((type, index) => (
                                    <Chip key={index} label={type} color="primary" />
                                )) || 'No food types specified'}
                            </Box>
                        </CardContent>
                    </Card>
                </Grid>

                {/* Menu Items */}
                <Grid item xs={12}>
                    <Card>
                        <CardContent>
                            <Typography variant="h5" gutterBottom>
                                Menu Items
                            </Typography>
                            <Grid container spacing={2}>
                                {foodTruck?.menu?.map((item, index) => (
                                    <Grid item xs={12} sm={6} md={4} key={index}>
                                        <Card variant="outlined">
                                            <CardContent>
                                                <Typography variant="h6">{item.name}</Typography>
                                                <Typography variant="body2" color="textSecondary">
                                                    {item.description}
                                                </Typography>
                                                <Typography variant="h6" color="primary">
                                                    ${item.price}
                                                </Typography>
                                                <Chip size="small" label={item.category} />
                                            </CardContent>
                                        </Card>
                                    </Grid>
                                ))}
                            </Grid>
                        </CardContent>
                    </Card>
                </Grid>
            </Grid>
        </Container>
    );
};

export default Dashboard; 