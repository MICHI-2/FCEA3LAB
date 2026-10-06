"""
Physical constants exposed through the Python API.
"""

# Universal gas constant in J/(kmol·K). This value is used internally by CEA and
# duplicated in many of the historical examples, so keep a canonical copy here.
R = 8314.51

__all__ = ["R"]
