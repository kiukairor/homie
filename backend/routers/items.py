from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from datetime import datetime

from backend.db.session import get_session
from backend.models.item import Item

router = APIRouter(prefix="/api/items", tags=["items"])


class ItemCreate(BaseModel):
    name: str
    quantity: str = "1"
    unit: Optional[str] = None
    category: Optional[str] = None


class ItemUpdate(BaseModel):
    name: Optional[str] = None
    quantity: Optional[str] = None
    unit: Optional[str] = None
    category: Optional[str] = None
    checked: Optional[bool] = None


class ItemResponse(BaseModel):
    id: str
    name: str
    quantity: str
    unit: Optional[str]
    category: Optional[str]
    checked: bool
    created_at: datetime

    model_config = {"from_attributes": True}


@router.get("", response_model=list[ItemResponse])
async def list_items(
    checked: Optional[bool] = None,
    session: AsyncSession = Depends(get_session),
):
    stmt = select(Item).order_by(Item.created_at)
    if checked is not None:
        stmt = stmt.where(Item.checked == checked)
    result = await session.execute(stmt)
    return result.scalars().all()


@router.post("", response_model=ItemResponse, status_code=201)
async def create_item(body: ItemCreate, session: AsyncSession = Depends(get_session)):
    item = Item(**body.model_dump())
    session.add(item)
    await session.commit()
    await session.refresh(item)
    return item


@router.patch("/{item_id}", response_model=ItemResponse)
async def update_item(
    item_id: str,
    body: ItemUpdate,
    session: AsyncSession = Depends(get_session),
):
    item = await session.get(Item, item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(item, field, value)
    await session.commit()
    await session.refresh(item)
    return item


@router.delete("/checked", status_code=204)
async def delete_checked(session: AsyncSession = Depends(get_session)):
    await session.execute(delete(Item).where(Item.checked == True))  # noqa: E712
    await session.commit()
    return Response(status_code=204)


@router.delete("/{item_id}", status_code=204)
async def delete_item(item_id: str, session: AsyncSession = Depends(get_session)):
    item = await session.get(Item, item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    await session.delete(item)
    await session.commit()
    return Response(status_code=204)
