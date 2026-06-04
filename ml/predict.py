"""
Prediction script — loads saved model artifacts, accepts a comma-separated
symptoms string as CLI argument, outputs a JSON prediction result.

Plan: docs/implementation-plan/python/01-ml-pipeline.md — Task 4

Usage:
    python ml/predict.py "fever,cough,headache"

Output (JSON):
    {
      "predicted_disease": "Common Cold",
      "recommended_specialization": "General Physician",
      "confidence": 0.87,
      "low_confidence": false,
      "matched_symptoms": ["fever", "cough", "headache"]
    }
"""

# TODO: Implement — see implementation plan above
