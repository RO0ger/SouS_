# SouS - Smart Meal Preparation Assistant

SouS is an iOS application that helps users prepare personalized meals based on ingredients they have available, aligned with their health and dietary goals.

## App Workflow

1. **Authentication**: New users complete an authentication process upon first launch.

2. **Onboarding**: Users provide personal details including:
   - Current weight
   - Target weight
   - Dietary preferences
   - Activity level
   - Target date
   - Health goals
   - Sex
   - Age
   - Location/country

3. **Ingredient Detection**:
   - Users access the camera function
   - They can take a photo or upload an existing image
   - Gemini API analyzes the image to detect available ingredients

4. **Personalized Meal Suggestions**:
   - Users see a list of detected ingredients
   - The app suggests 2-3 meals that match:
     - Available ingredients
     - User's dietary preferences
     - Health goals (weight loss/gain)
     - Personal profile data

5. **Recipe Details**:
   - Upon selecting a meal, users access a detailed recipe page
   - Features include:
     - Preparation time
     - Interactive cooking timer
     - Complete ingredient list
     - Step-by-step cooking instructions

SouS creates a personalized cooking experience by connecting available ingredients with individual health goals and preferences. 