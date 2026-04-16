import logging
import sys
from typing import Any


def _build_logger() -> logging.Logger:
    logger = logging.getLogger("glamai")
    if logger.handlers:
        return logger  # already configured

    logger.setLevel(logging.DEBUG)

    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(logging.DEBUG)

    fmt = logging.Formatter(
        fmt="%(asctime)s [%(levelname)-8s] [%(name)s] %(message)s",
        datefmt="%H:%M:%S",
    )
    handler.setFormatter(fmt)
    logger.addHandler(handler)
    logger.propagate = False
    return logger


_root = _build_logger()


def get_logger(tag: str) -> logging.Logger:
    """Return a child logger namespaced under 'glamai.<tag>'."""
    return _root.getChild(tag)


def log_request(tag: str, method: str, path: str, extra: Any = None) -> None:
    logger = get_logger(tag)
    msg = f"→ {method} {path}"
    if extra:
        msg += f" | {extra}"
    logger.info(msg)


def log_response(tag: str, method: str, path: str, status: int) -> None:
    logger = get_logger(tag)
    logger.info(f"← {method} {path} [{status}]")
